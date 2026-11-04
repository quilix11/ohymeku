// Existing installations can fetch this update and retire the old guide cache.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys
    .filter(key => key.startsWith('ohymeku-install-'))
    .map(key => caches.delete(key))))
    .then(() => self.registration.unregister()));
});
