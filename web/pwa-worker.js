// Keep app/API responses fresh. Only the small installation guide is cached.
const CACHE = 'ohymeku-install-v1';
const guide = new URL('install.html', self.registration.scope).href;
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll([
    guide, 'install.js', 'manifest.json', 'icons/meku-192.png', 'icons/meku-512.png',
    'icons/apple-touch-icon.png', 'favicon.png'
  ])));
  self.skipWaiting();
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys
    .filter(key => key.startsWith('ohymeku-install-') && key !== CACHE)
    .map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  if (event.request.mode !== 'navigate' || !event.request.url.startsWith(self.registration.scope)) return;
  event.respondWith(fetch(event.request).catch(async () =>
    (await caches.match(guide)) || Response.error()));
});
