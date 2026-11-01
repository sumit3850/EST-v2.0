/* EST native bridge — loaded only inside the Capacitor shell (Android / iOS).
   The web app keeps using standard browser APIs; this file fills the gaps a
   WebView has:  permissions up front, file downloads (blob → native share
   sheet), external links in the system browser, status bar / splash. */
(function () {
  const Cap = window.Capacitor;
  if (!Cap || !Cap.isNativePlatform || !Cap.isNativePlatform()) return;
  const P = Cap.Plugins || {};
  const platform = Cap.getPlatform ? Cap.getPlatform() : 'native';
  document.documentElement.classList.add('est-native', 'est-' + platform);

  /* ── permissions: ask once at start so GPS tagging and camera work at first use ── */
  (async () => {
    try { if (P.Geolocation) { const s = await P.Geolocation.checkPermissions(); if (s.location !== 'granted') await P.Geolocation.requestPermissions(); } } catch (e) {}
  })();

  /* ── status bar & splash ── */
  try { P.StatusBar && P.StatusBar.setBackgroundColor && P.StatusBar.setBackgroundColor({ color: '#0d2018' }); } catch (e) {}
  try { P.StatusBar && P.StatusBar.setStyle && P.StatusBar.setStyle({ style: 'DARK' }); } catch (e) {}
  window.addEventListener('load', () => { try { P.SplashScreen && P.SplashScreen.hide(); } catch (e) {} });

  /* ── downloads: a WebView cannot "download" a blob — write it to the app cache and
        hand it to the share sheet (Save to Files / Drive / WhatsApp / Gmail …) ── */
  async function saveBlob(blob, filename) {
    if (!P.Filesystem || !P.Share) throw new Error('native file plugins unavailable');
    const b64 = await new Promise((res, rej) => { const r = new FileReader(); r.onload = () => res(String(r.result).split(',')[1]); r.onerror = rej; r.readAsDataURL(blob); });
    const path = 'est/' + (filename || 'EST-export.bin').replace(/[^\w.\-]+/g, '_');
    await P.Filesystem.writeFile({ path, data: b64, directory: 'CACHE', recursive: true });
    const { uri } = await P.Filesystem.getUri({ path, directory: 'CACHE' });
    await P.Share.share({ title: filename, url: uri, dialogTitle: 'Save or share ' + filename });
    return uri;
  }
  window.__nativeSaveBlob = saveBlob;

  // Intercept the standard "create <a download> and click it" pattern the pages use
  const origClick = HTMLAnchorElement.prototype.click;
  HTMLAnchorElement.prototype.click = function () {
    try {
      const href = this.getAttribute('href') || '';
      const dl = this.hasAttribute('download');
      if (dl && (href.startsWith('blob:') || href.startsWith('data:'))) {
        const name = this.getAttribute('download') || 'EST-export';
        fetch(href).then(r => r.blob()).then(b => saveBlob(b, name)).catch(err => alert('Could not save the file: ' + (err && err.message || err)));
        return;
      }
      // external http(s) links open in the system browser
      if (/^https?:\/\//i.test(href) && !/localhost/.test(href) && this.target === '_blank' && P.Browser) {
        P.Browser.open({ url: href }); return;
      }
    } catch (e) {}
    return origClick.apply(this, arguments);
  };

  // window.open(url,'_blank') for external pages (Razorpay docs, EST website) → system browser;
  // the risk-report print window (window.open('') + document.write) is left to the WebView.
  const origOpen = window.open;
  window.open = function (url, target, features) {
    try { if (url && /^https?:\/\//i.test(String(url)) && !/localhost/.test(String(url)) && P.Browser) { P.Browser.open({ url: String(url) }); return null; } } catch (e) {}
    return origOpen.apply(window, arguments);
  };

  /* ── Android hardware back button: step back inside the app instead of closing it ── */
  try {
    P.App && P.App.addListener && P.App.addListener('backButton', ({ canGoBack }) => {
      const openModal = document.querySelector('.modal-ov.open, #manual-edit-modal[style*="flex"]');
      if (openModal) { openModal.classList.remove('open'); if (openModal.style) openModal.style.display = 'none'; return; }
      if (typeof window.goBack === 'function') { try { window.goBack(); return; } catch (e) {} }
      if (canGoBack) history.back(); else P.App.minimizeApp && P.App.minimizeApp();
    });
  } catch (e) {}

  /* ── network status → let the pages' existing online/offline handlers run ── */
  try { P.Network && P.Network.addListener && P.Network.addListener('networkStatusChange', s => window.dispatchEvent(new Event(s.connected ? 'online' : 'offline'))); } catch (e) {}
})();
