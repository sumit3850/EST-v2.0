/* EST v2.0 Service Worker — Add this file to your GitHub repo root */
const CACHE_NAME = 'est-v2.0.2';
const APP_SHELL = [
  './',
  './index.html'
];

self.addEventListener('install', e => {
  console.log('[EST-SW] Installing...');
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(APP_SHELL);
    }).then(() => {
      console.log('[EST-SW] Cached app shell');
      return self.skipWaiting();
    })
  );
});

self.addEventListener('activate', e => {
  console.log('[EST-SW] Activating...');
  e.waitUntil(
    caches.keys().then(keys => {
      return Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      );
    }).then(() => {
      console.log('[EST-SW] Old caches cleared');
      return self.clients.claim();
    })
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;

  // Skip external APIs (GPS, GitHub, etc.)
  const url = new URL(e.request.url);
  if (url.origin !== self.location.origin) {
    return; // Let browser handle external requests normally
  }

  e.respondWith(
    caches.open(CACHE_NAME).then(cache => {
      return fetch(e.request).then(resp => {
        if (resp && resp.ok) {
          cache.put(e.request, resp.clone());
        }
        return resp;
      }).catch(() => {
        return cache.match(e.request).then(cached => {
          if (cached) {
            console.log('[EST-SW] Serving from cache:', e.request.url);
            return cached;
          }
          console.log('[EST-SW] Not in cache:', e.request.url);
          return new Response('Offline — data saved locally in app', {
            status: 503,
            headers: { 'Content-Type': 'text/plain' }
          });
        });
      });
    })
  );
});

// Listen for messages from app
self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
