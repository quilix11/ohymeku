(() => {
  const button = document.getElementById('install');
  const status = document.getElementById('install-status');
  let prompt;
  let isInstalled = false;
  const installed = () => {
    isInstalled = true;
    if (button) button.hidden = true;
    if (status) status.textContent = 'Ohymeku встановлено! Відкривай застосунок через іконку Meku.';
  };
  if (window.matchMedia('(display-mode: standalone)').matches || navigator.standalone) installed();
  window.addEventListener('beforeinstallprompt', event => {
    if (!button) return; // Keep the browser's install option available in the app.
    event.preventDefault();
    prompt = event;
    button.textContent = 'Встановити на телефон';
    button.hidden = false;
  });
  window.addEventListener('appinstalled', installed);
  button?.addEventListener('click', async () => {
    if (!prompt) {
      const ios = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
        (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
      document.getElementById(ios ? 'ios' : 'android')?.scrollIntoView({
        behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth'
      });
      if (status) status.textContent = ios
        ? 'У Safari: «Поділитися» → «На початковий екран».'
        : 'У Chrome: меню ⋮ → «Додати на головний екран» → «Встановити».';
      return;
    }
    const request = prompt;
    prompt = null;
    button.disabled = true;
    let accepted = false;
    try {
      await request.prompt();
      const result = await request.userChoice;
      accepted = result.outcome === 'accepted';
      if (status) status.textContent = result.outcome === 'accepted'
        ? 'Підтвердь встановлення у вікні браузера.'
        : 'Можна встановити пізніше через меню браузера або просто відкрити Ohymeku.';
    } catch (_) {
      if (status) status.textContent = 'Відкрий меню браузера → «Додати на головний екран».';
    } finally {
      button.disabled = false;
      button.textContent = 'Як встановити на телефон';
      button.hidden = isInstalled || accepted;
    }
  });
  if ('serviceWorker' in navigator && window.isSecureContext) {
    navigator.serviceWorker.register(new URL('pwa-worker.js', document.baseURI), {scope: './'})
      .catch(() => { /* Manual installation instructions remain available. */ });
  }
})();
