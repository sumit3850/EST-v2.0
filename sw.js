/* EST v2.0 Service Worker — Enhanced Offline Support */
const CACHE_NAME = 'est-v2.0.3';
const STATIC_ASSETS = [
  './',
  './index.html',
  './manifest.json'
];

// Install event - cache app shell
self.addEventListener('install', e => {
  console.log('[EST-SW] Installing Service Worker...');
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('[EST-SW] Caching app shell...');
        return cache.addAll(STATIC_ASSETS)
          .catch(err => {
            console.warn('[EST-SW] Failed to cache some assets:', err);
            // Continue even if some assets fail
            return cache.addAll(STATIC_ASSETS.filter(url => url !== './manifest.json'));
          });
      })
      .then(() => {
        console.log('[EST-SW] App shell cached successfully');
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', e => {
  console.log('[EST-SW] Activating Service Worker...');
  e.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('[EST-SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('[EST-SW] Claiming clients...');
      return self.clients.claim();
    })
  );
});

// Fetch event - intelligent caching strategies
self.addEventListener('fetch', e => {
  const { request } = e;
  const url = new URL(request.url);

  // Only handle GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip external APIs (GPS, GitHub, etc.)
  if (url.origin !== self.location.origin) {
    console.log('[EST-SW] Skipping external API:', url.origin);
    return;
  }

  // Strategy 1: Stale-while-revalidate for assets (images, fonts, CSS)
  if (url.pathname.match(/\.(png|jpg|jpeg|gif|svg|webp|woff|woff2|ttf|css)$/i)) {
    e.respondWith(
      caches.open(CACHE_NAME).then(cache => {
        return cache.match(request).then(cached => {
          const fetchPromise = fetch(request).then(resp => {
            if (resp && resp.ok) {
              cache.put(request, resp.clone());
              console.log('[EST-SW] Updated cache for:', url.pathname);
            }
            return resp;
          }).catch(err => {
            console.log('[EST-SW] Fetch failed, using cache for:', url.pathname);
            return cached;
          });
          return cached || fetchPromise;
        });
      })
    );
    return;
  }

  // Strategy 2: Network-first for HTML/JS (main content)
  e.respondWith(
    fetch(request)
      .then(resp => {
        if (resp && resp.ok) {
          caches.open(CACHE_NAME).then(cache => {
            cache.put(request, resp.clone());
            console.log('[EST-SW] Cached from network:', url.pathname);
          });
        }
        return resp;
      })
      .catch(err => {
        console.log('[EST-SW] Network failed, trying cache for:', url.pathname);
        return caches.match(request).then(cached => {
          if (cached) {
            console.log('[EST-SW] Serving from cache:', url.pathname);
            return cached;
          }
          // Offline fallback
          console.warn('[EST-SW] Not in cache:', url.pathname);
          return new Response(
            '<div style="padding: 20px; text-align: center; font-family: sans-serif;"><h2>📡 Offline</h2><p>This resource is not available offline yet.</p><p>Your data is saved locally.</p></div>',
            {
              status: 503,
              statusText: 'Service Unavailable',
              headers: { 'Content-Type': 'text/html' }
            }
          );
        });
      })
  );
});

// Message event - handle app requests
self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') {
    console.log('[EST-SW] Skip waiting signal received');
    self.skipWaiting();
  }
  if (e.data === 'GET_CACHE_SIZE') {
    getCacheSize().then(size => {
      e.ports[0].postMessage({ cacheSize: size });
    });
  }
});

// Helper function to calculate cache size
function getCacheSize() {
  return caches.open(CACHE_NAME).then(cache => {
    return cache.keys().then(requests => {
      let totalSize = 0;
      return Promise.all(
        requests.map(req => {
          return cache.match(req).then(resp => {
            if (resp) totalSize += new Blob([resp.body]).size;
          });
        })
      ).then(() => totalSize);
    });
  });
}
