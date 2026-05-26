/**
 * EST v2.0 Offline Helper
 * Manages offline state detection and user notifications
 */

// Register Service Worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js')
      .then(reg => {
        console.log('[EST] Service Worker registered:', reg.scope);
        // Check for updates periodically
        setInterval(() => reg.update(), 60000);
      })
      .catch(err => {
        console.warn('[EST] Service Worker registration failed:', err);
      });
  });
}

// Track offline/online status
let isOffline = !navigator.onLine;

window.addEventListener('online', () => {
  isOffline = false;
  document.body.classList.remove('est-offline-mode');
  showOfflineNotification('✅ Back online! Your data will sync.', 'success');
  console.log('[EST] Online connection restored');
});

window.addEventListener('offline', () => {
  isOffline = true;
  document.body.classList.add('est-offline-mode');
  showOfflineNotification('📡 You are offline. Data saved locally.', 'warning');
  console.log('[EST] Offline mode activated');
});

// Initialize offline state on load
if (!navigator.onLine) {
  document.body.classList.add('est-offline-mode');
  console.log('[EST] App started in offline mode');
}

// Notification system
function showOfflineNotification(message, type = 'info') {
  const notification = document.createElement('div');
  notification.className = `est-offline-notify est-offline-notify-${type}`;
  notification.textContent = message;
  notification.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    padding: 12px 16px;
    font-size: 13px;
    font-weight: 600;
    z-index: 10000;
    text-align: center;
    animation: slideDown 0.3s ease-out;
  `;
  
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.style.animation = 'slideUp 0.3s ease-in';
    setTimeout(() => notification.remove(), 300);
  }, 4000);
}

// Request persistent storage
function requestPersistentStorage() {
  if (navigator.storage && navigator.storage.persist) {
    navigator.storage.persist().then(persistent => {
      console.log('[EST] Persistent storage:', persistent ? 'granted' : 'denied');
    });
  }
}

// Check storage quota
function checkStorageQuota() {
  if (navigator.storage && navigator.storage.estimate) {
    navigator.storage.estimate().then(estimate => {
      const used = (estimate.usage / 1024 / 1024).toFixed(2);
      const quota = (estimate.quota / 1024 / 1024).toFixed(2);
      console.log(`[EST] Storage: ${used}MB / ${quota}MB`);
      return { used: estimate.usage, quota: estimate.quota };
    });
  }
}

// Export for external use
window.EST_OFFLINE = {
  isOffline: () => isOffline,
  requestStorage: requestPersistentStorage,
  checkQuota: checkStorageQuota,
  showNotification: showOfflineNotification
};

console.log('[EST] Offline helper loaded');
