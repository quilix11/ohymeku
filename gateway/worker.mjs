const upstream = 'https://generativelanguage.googleapis.com/v1beta/';
const routes = {
  text: { model: 'gemini-2.5-flash-lite', timeout: 20000, limit: 24, window: 60000, daily: 200 },
  portraits: { model: 'gemini-3.1-flash-lite-image', timeout: 120000, limit: 3, window: 3600000, daily: 20 },
  speech: { model: 'gemini-2.5-flash-preview-tts', timeout: 35000, limit: 10, window: 60000, daily: 80 },
};
const error = (code, message, headers = {}) => Response.json(
  { error: { code, status: code === 429 ? 'RESOURCE_EXHAUSTED' : 'GATEWAY_ERROR', message } },
  { status: code, headers });
const redact = (value, key) => String(value ?? '').split(key).join('[redacted]')
  .replace(/AIza[A-Za-z0-9_-]+|AQ\.[A-Za-z0-9_.-]+/g, '[redacted]').slice(0, 500);

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/health' && request.method === 'GET') {
      return Response.json({ ready: Boolean(env.GEMINI_API_KEY && env.REQUEST_BUDGET) });
    }
    const origin = request.headers.get('Origin');
    if (origin !== env.ALLOWED_ORIGIN) return error(403, 'Цей сайт не має доступу до спільного Gemini.');
    const headers = {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Expose-Headers': 'X-Gemini-Model, Retry-After',
      'Vary': 'Origin', 'Cache-Control': 'no-store',
    };
    const route = url.pathname.startsWith('/api/') ? url.pathname.substring(5) : '';
    const config = routes[route];
    if (!config) return error(404, 'Невідомий маршрут.', headers);
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
    if (request.method !== 'POST') return error(405, 'Потрібен POST.', headers);
    if (!env.GEMINI_API_KEY || !env.REQUEST_BUDGET) return error(503, 'Спільний Gemini ще не налаштований на сервері.', headers);
    if (!request.headers.get('Content-Type')?.startsWith('application/json')) return error(415, 'Потрібен JSON.', headers);
    const maxBytes = route === 'portraits' ? 4000000 : 100000;
    if (Number(request.headers.get('Content-Length') || 0) > maxBytes) return error(413, 'Запит завеликий.', headers);
    let payload;
    try {
      // Read incrementally: clients cannot bypass the bound by omitting Content-Length.
      const reader = request.body?.getReader();
      if (!reader) return error(400, 'Порожній запит.', headers);
      const chunks = []; let size = 0;
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        size += value.byteLength;
        if (size > maxBytes) { await reader.cancel(); return error(413, 'Запит завеликий.', headers); }
        chunks.push(value);
      }
      const bytes = new Uint8Array(size); let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
      payload = JSON.parse(new TextDecoder().decode(bytes)).payload;
      if (!payload || typeof payload !== 'object' || Array.isArray(payload)) throw new Error();
    } catch { return error(400, 'Некоректний JSON запиту.', headers); }
    // Ignore client model selection and unsupported costly generation options.
    let body;
    if (route === 'portraits') {
      if (!Array.isArray(payload.input) || payload.input.length > 3) return error(400, 'Некоректні дані портретів.', headers);
      body = { model: config.model, store: false, response_modalities: ['image'],
        generation_config: { image_generation_config: { aspect_ratio: '1:1' } }, input: payload.input };
    } else {
      if (!Array.isArray(payload.contents) || payload.contents.length > 24) return error(400, 'Некоректний текст запиту.', headers);
      const inputConfig = payload.generationConfig ?? {};
      body = { contents: payload.contents,
        ...(payload.systemInstruction ? { systemInstruction: payload.systemInstruction } : {}),
        generationConfig: route === 'text' ? {
          responseFormat: inputConfig.responseFormat ?? { text: { mimeType: 'APPLICATION_JSON' } },
          maxOutputTokens: Math.min(8192, Math.max(1, Number(inputConfig.maxOutputTokens) || 2048)),
          thinkingConfig: { thinkingBudget: 0 },
        } : { responseModalities: ['AUDIO'], maxOutputTokens: 2048,
          speechConfig: inputConfig.speechConfig },
      };
    }
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const hash = [...new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(ip)))]
      .map(b => b.toString(16).padStart(2, '0')).join('');
    const budget = env.REQUEST_BUDGET.get(env.REQUEST_BUDGET.idFromName('global'));
    let allowance;
    try {
      allowance = await budget.fetch('https://budget/check', {
        method: 'POST', body: JSON.stringify({ route, ip: hash }),
      });
    } catch { return error(503, 'Ліміт спільного Gemini тимчасово недоступний.', headers); }
    if (!allowance.ok) return error(429, 'Досягнуто ліміт спільного Gemini. Спробуй пізніше або підключи власний ключ.',
      { ...headers, 'Retry-After': allowance.headers.get('Retry-After') || '60' });
    const controller = new AbortController();
    const cancel = () => controller.abort();
    request.signal.addEventListener('abort', cancel, { once: true });
    if (request.signal.aborted) cancel();
    const timer = setTimeout(cancel, config.timeout);
    try {
      let model = config.model;
      const send = () => fetch(upstream + (route === 'portraits' ? 'interactions' : `models/${model}:generateContent`), {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
        body: JSON.stringify(body), signal: controller.signal,
      });
      let response = await send();
      if (route === 'text' && response.status === 404) {
        await response.body?.cancel();
        model = 'gemini-flash-lite-latest';
        delete body.generationConfig.thinkingConfig;
        response = await send(); // The original deadline still applies.
      }
      headers['X-Gemini-Model'] = model;
      if (!response.ok) {
        let cause;
        try { cause = (await response.json()).error; } catch { /* Non-JSON provider outage. */ }
        return Response.json({ error: { code: response.status,
          status: redact(cause?.status || 'UPSTREAM_ERROR', env.GEMINI_API_KEY),
          message: redact(cause?.message || 'Gemini не повернув причину помилки.', env.GEMINI_API_KEY) } },
          { status: response.status, headers });
      }
      // Read before clearing the timer so a stalled response body also times out.
      const bytes = await response.arrayBuffer();
      return new Response(bytes, { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } });
    } catch {
      return error(controller.signal.aborted ? 504 : 502,
        controller.signal.aborted ? 'Gemini не відповів вчасно; запит скасовано.' : 'Сервер не зміг з’єднатися з Gemini.', headers);
    } finally {
      clearTimeout(timer); request.signal.removeEventListener('abort', cancel);
    }
  },
};

// A single Durable Object makes quotas atomic across all Worker instances.
// CORS restricts browser use; hard daily caps bound abuse by other HTTP clients.
export class RequestBudget {
  constructor(state) { this.storage = state.storage; }
  async fetch(request) {
    let input;
    try { input = await request.json(); } catch { return error(400, 'Bad budget input'); }
    const config = routes[input.route];
    if (!config || !/^[a-f0-9]{64}$/.test(input.ip)) return error(400, 'Bad budget input');
    const now = Date.now(), day = Math.floor(now / 86400000), bucket = Math.floor(now / config.window);
    const dailyKey = `day:${input.route}:${day}`, userKey = `ip:${input.route}:${input.ip}:${bucket}`;
    const allowed = await this.storage.transaction(async tx => {
      const daily = await tx.get(dailyKey) || 0, user = await tx.get(userKey) || 0;
      if (daily >= config.daily || user >= config.limit) return false;
      await tx.put({ [dailyKey]: daily + 1, [userKey]: user + 1 });
      return true;
    });
    if (!await this.storage.getAlarm()) await this.storage.setAlarm((day + 1) * 86400000);
    return allowed ? new Response('ok') : error(429, 'Shared quota reached', { 'Retry-After': String(Math.ceil(config.window / 1000)) });
  }
  async alarm() { await this.storage.deleteAll(); }
}
