/* EST v2.0 Service Worker — Offline-First */
const CACHE_NAME = 'est-v2.0.81';
const STATIC_ASSETS = [
  './',
  './index.html',
  './dashboard.html',
  './manifest.json',
  './dashboard-manifest.json',
  './offline-helper.js',
  './offline-styles.css',
  './config.json'
];

// Install — fetch fresh copies from network and cache them
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS.map(url => new Request(url, { cache: 'no-store' }))))
      .then(() => self.skipWaiting())
  );
});

// Activate — delete ALL old caches, claim clients, then notify them to reload
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
      .then(() => self.clients.matchAll({ includeUncontrolled: true }))
      .then(clients => clients.forEach(c => c.postMessage({ type: 'UPDATE_AVAILABLE', version: CACHE_NAME })))
  );
});

// Fetch — network-first for HTML (always get latest), cache-first for everything else
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;

  const url = new URL(e.request.url);

  // External: GitHub API, Google Fonts, GPS — pass through, never cache
  if (url.origin !== self.location.origin) return;

  // config.json is network-first too — ensures deleted/updated users are reflected immediately
  const isHtml = url.pathname.endsWith('.html') || url.pathname.endsWith('/') || url.pathname.endsWith('config.json');

  if (isHtml) {
    // Network-first for HTML: always show latest, fall back to cache if offline
    e.respondWith(
      fetch(e.request, { cache: 'no-store' })
        .then(resp => {
          if (resp && resp.ok) {
            caches.open(CACHE_NAME).then(cache => cache.put(e.request, resp.clone()));
          }
          return resp;
        })
        .catch(() => caches.match(e.request))
    );
  } else {
    // Cache-first for JS/CSS/JSON: fast load, update in background
    e.respondWith(
      caches.match(e.request).then(cached => {
        const networkFetch = fetch(e.request).then(resp => {
          if (resp && resp.ok) {
            caches.open(CACHE_NAME).then(cache => cache.put(e.request, resp.clone()));
          }
          return resp;
        });
        return cached || networkFetch.catch(() => new Response('', { status: 503 }));
      })
    );
  }
});

self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});
