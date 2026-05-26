/* EST v2.0 Service Worker — Offline-First */
const CACHE_NAME = 'est-v2.0.5';
const STATIC_ASSETS = [
  './',
  './index.html',
  './dashboard.html',
  './manifest.json',
  './offline-helper.js',
  './offline-styles.css',
  './config.json'
];

// Install — pre-cache all critical assets
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate — remove old caches, claim clients immediately
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// Fetch — cache-first for same-origin, network-only for external
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;

  const url = new URL(e.request.url);

  // External: GitHub API, Google Fonts, GPS — always go to network, don't cache
  if (url.origin !== self.location.origin) return;

  // Same-origin: cache-first
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;

      // Not in cache yet — fetch and cache for next time
      return fetch(e.request).then(resp => {
        if (resp && resp.ok) {
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, resp.clone()));
        }
        return resp;
      }).catch(() => {
        // Offline and not cached — show minimal fallback
        const isHtml = e.request.headers.get('accept')?.includes('text/html');
        if (isHtml) {
          return caches.match('./index.html');
        }
        return new Response('', { status: 503 });
      });
    })
  );
});

self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});
