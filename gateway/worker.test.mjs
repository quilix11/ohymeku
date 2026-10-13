import { test } from 'node:test';
import assert from 'node:assert/strict';
import { webcrypto } from 'node:crypto';
import worker, { RequestBudget } from './worker.mjs';
if (!globalThis.crypto) globalThis.crypto = webcrypto;
const origin = 'https://quilix11.github.io';
const env = () => ({ ALLOWED_ORIGIN: origin, GEMINI_API_KEY: 'synthetic-server-secret',
  REQUEST_BUDGET: { idFromName: x => x, get: () => ({ fetch: async () => new Response('ok') }) } });
const request = (route = 'text', payload = { contents: [] }, opts = {}) => new Request(`https://gateway.test/api/${route}`, {
  method: 'POST', headers: { Origin: origin, 'Content-Type': 'application/json', 'CF-Connecting-IP': '192.0.2.1', ...opts.headers },
  body: opts.body ?? JSON.stringify({ model: 'expensive-client-choice', payload }), ...opts,
});
test('missing secret and unapproved origins make no provider call', async () => {
  const old = globalThis.fetch; globalThis.fetch = () => { throw new Error('must not call provider'); };
  try {
    const missing = env(); delete missing.GEMINI_API_KEY;
    assert.equal((await worker.fetch(request(), missing)).status, 503);
    assert.equal((await worker.fetch(request('text', {}, { headers: { Origin: 'https://other.test', 'Content-Type': 'application/json' } }), env())).status, 403);
    assert.equal((await worker.fetch(new Request('https://gateway.test/api/text', { method: 'POST', body: '{}' }), env())).status, 403);
  } finally { globalThis.fetch = old; }
});
test('health and CORS preflight work without exposing the key', async () => {
  const health = await worker.fetch(new Request('https://gateway.test/health'), env());
  assert.deepEqual(await health.json(), { ready: true });
  const preflight = await worker.fetch(new Request('https://gateway.test/api/text', { method: 'OPTIONS', headers: { Origin: origin } }), env());
  assert.equal(preflight.status, 204); assert.equal(preflight.headers.get('Access-Control-Allow-Origin'), origin);
});
test('text, portraits and speech select server models and keep the key upstream', async () => {
  const old = globalThis.fetch; const calls = [];
  globalThis.fetch = async (url, options) => { calls.push({ url, options }); return Response.json({ candidates: [] }); };
  try {
    for (const route of ['text', 'portraits', 'speech']) {
      const response = await worker.fetch(request(route, { contents: [], input: [{ type: 'text', text: 'fixture' }],
        generationConfig: { maxOutputTokens: 100000, thinkingConfig: { thinkingLevel: 'HIGH' } }, model: 'expensive' }), env());
      assert.equal(response.status, 200);
      assert.equal(response.headers.get('Access-Control-Allow-Origin'), origin);
      assert.ok(!(await response.text()).includes('synthetic-server-secret'));
      assert.equal(calls.at(-1).options.headers['x-goog-api-key'], 'synthetic-server-secret');
    }
    const text = JSON.parse(calls[0].options.body);
    assert.ok(calls[0].url.endsWith('models/gemini-2.5-flash-lite:generateContent'));
    assert.equal(text.generationConfig.maxOutputTokens, 8192);
    assert.deepEqual(text.generationConfig.thinkingConfig, { thinkingBudget: 0 });
    const images = JSON.parse(calls[1].options.body);
    assert.equal(images.model, 'gemini-3.1-flash-lite-image'); assert.equal(images.store, false);
    assert.ok(calls[2].url.endsWith('models/gemini-2.5-flash-preview-tts:generateContent'));
  } finally { globalThis.fetch = old; }
});
test('provider errors preserve cause while redacting secret and status', async () => {
  const old = globalThis.fetch;
  globalThis.fetch = async () => Response.json({ error: { status: 'PERMISSION_DENIED', message: 'invalid synthetic-server-secret' } }, { status: 403 });
  try {
    const response = await worker.fetch(request(), env()); const body = await response.text();
    assert.equal(response.status, 403); assert.ok(body.includes('PERMISSION_DENIED'));
    assert.ok(!body.includes('synthetic-server-secret')); assert.ok(body.includes('[redacted]'));
    assert.equal(response.headers.get('X-Gemini-Model'), 'gemini-2.5-flash-lite');
  } finally { globalThis.fetch = old; }
});
test('malformed, oversized and unknown requests do not reach provider', async () => {
  assert.equal((await worker.fetch(request('text', {}, { body: '{broken' }), env())).status, 400);
  assert.equal((await worker.fetch(request('text', {}, { body: 'x'.repeat(100001) }), env())).status, 413);
  assert.equal((await worker.fetch(request('unknown'), env())).status, 404);
  assert.equal((await worker.fetch(request('portraits', { input: [1, 2, 3, 4] }), env())).status, 400);
});
test('quota rejection prevents spending and exposes retry information', async () => {
  const limited = env(); limited.REQUEST_BUDGET.get = () => ({ fetch: async () => new Response('', { status: 429, headers: { 'Retry-After': '120' } }) });
  const response = await worker.fetch(request(), limited);
  assert.equal(response.status, 429); assert.equal(response.headers.get('Retry-After'), '120');
});
test('upstream request cancels when browser disconnects', async () => {
  const old = globalThis.fetch; const abort = new AbortController();
  globalThis.fetch = async (_, options) => {
    abort.abort(); assert.equal(options.signal.aborted, true);
    throw new DOMException('cancelled', 'AbortError');
  };
  try {
    const response = await worker.fetch(request('text', { contents: [] }, { signal: abort.signal }), env());
    assert.equal(response.status, 504);
  } finally { globalThis.fetch = old; }
});
class Storage {
  data = new Map(); alarm = null; chain = Promise.resolve();
  async get(key) { return this.data.get(key); }
  async put(items) { for (const [k, v] of Object.entries(items)) this.data.set(k, v); }
  transaction(fn) { const result = this.chain.then(() => fn(this)); this.chain = result.catch(() => {}); return result; }
  async getAlarm() { return this.alarm; }
  async setAlarm(value) { this.alarm = value; }
  async deleteAll() { this.data.clear(); this.alarm = null; }
}
const check = (budget, ip, route = 'text') => budget.fetch(new Request('https://budget/check', { method: 'POST', body: JSON.stringify({ route, ip }) }));
test('atomic concurrent quotas cap per-IP use and expire counters', async () => {
  const storage = new Storage(), budget = new RequestBudget({ storage });
  const results = await Promise.all(Array.from({ length: 30 }, () => check(budget, 'a'.repeat(64))));
  assert.equal(results.filter(r => r.ok).length, 24);
  assert.equal((await check(budget, 'b'.repeat(64))).status, 200);
  assert.ok(storage.alarm > Date.now());
  await budget.alarm(); assert.equal(storage.data.size, 0);
  assert.equal((await check(budget, 'a'.repeat(64))).status, 200);
});
test('global image daily cap holds across distinct users', async () => {
  const budget = new RequestBudget({ storage: new Storage() });
  const results = await Promise.all(Array.from({ length: 25 }, (_, i) => check(budget, i.toString(16).padStart(64, '0'), 'portraits')));
  assert.equal(results.filter(r => r.ok).length, 20);
  assert.equal(results.filter(r => r.status === 429).length, 5);
});

test('missing text model falls back once to Lite without retrying quota errors', async () => {
  const old = globalThis.fetch; const urls = [];
  globalThis.fetch = async url => { urls.push(url); return Response.json({}, { status: urls.length === 1 ? 404 : 200 }); };
  try {
    const response = await worker.fetch(request(), env());
    assert.equal(response.status, 200); assert.equal(urls.length, 2);
    assert.ok(urls[1].endsWith('models/gemini-flash-lite-latest:generateContent'));
    assert.equal(response.headers.get('X-Gemini-Model'), 'gemini-flash-lite-latest');
    urls.length = 0; globalThis.fetch = async url => { urls.push(url); return Response.json({}, { status: 429 }); };
    assert.equal((await worker.fetch(request(), env())).status, 429); assert.equal(urls.length, 1);
  } finally { globalThis.fetch = old; }
});
