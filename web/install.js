// Retire the previous PWA install helper; native testers now use Firebase.
(async () => {
  if (!('serviceWorker' in navigator)) return;
  try {
    const scope = new URL('./', document.baseURI).href;
    const script = new URL('pwa-worker.js', document.baseURI).href;
    for (const registration of await navigator.serviceWorker.getRegistrations()) {
      const worker = registration.active || registration.waiting || registration.installing;
      if (registration.scope === scope && worker?.scriptURL === script) {
        await registration.unregister();
      }
    }
    if ('caches' in window) {
      for (const key of await caches.keys()) {
        if (key.startsWith('ohymeku-install-')) await caches.delete(key);
      }
    }
  } catch (_) { /* Firebase link works even if browser storage is unavailable. */ }
})();
