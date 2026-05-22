// Main JavaScript for AD Manager Portal v4.0

// Utility functions
function showToast(message, type = 'info') {
  console.log(`[${type.toUpperCase()}] ${message}`);
}

function confirmAction(message) {
  return confirm(message);
}

// Auto-refresh for dashboard stats (optional)
function setupAutoRefresh() {
  // Refresh every 60 seconds if on dashboard
  if (window.location.pathname === '/dashboard') {
    setInterval(() => {
      location.reload();
    }, 60000);
  }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
  setupAutoRefresh();
  
  // Add smooth scrolling
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });
});

// Format MAC address
function formatMAC(mac) {
  return mac.replace(/(..)(..)(..)(..)(..)(..)/, '$1:$2:$3:$4:$5:$6').toUpperCase();
}

// Format uptime
function formatUptime(seconds) {
  if (!seconds) return '-';
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  if (days > 0) return `${days}д ${hours}ч`;
  if (hours > 0) return `${hours}ч ${mins}м`;
  return `${mins}м`;
}

console.log('AD Manager Portal v4.0 loaded');
