export default defineNuxtPlugin(() => {
  if (!('serviceWorker' in navigator)) {
    return
  }

  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/pwa-sw.js').catch(() => {
      // PWA is an enhancement; failed registration should not block the blog.
    })
  })
})
