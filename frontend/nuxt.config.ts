export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  srcDir: 'app',
  ssr: true,
  modules: ['@pinia/nuxt', '@nuxtjs/tailwindcss', '@nuxtjs/color-mode'],
  typescript: {
    strict: true,
    typeCheck: true
  },
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    apiServerBase: process.env.NUXT_API_SERVER_BASE || process.env.NUXT_PUBLIC_API_BASE || '/api',
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || '/api'
    }
  },
  app: {
    head: {
      titleTemplate: '%s | 河南娃的小窝',
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: '河南娃的小窝，记录编程、深度学习、读书与生活碎片。' },
        { name: 'theme-color', content: '#d99a2b' },
        { name: 'mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-title', content: '小窝后台' },
        { name: 'apple-mobile-web-app-status-bar-style', content: 'default' }
      ],
      link: [
        { rel: 'manifest', href: '/manifest.webmanifest' },
        { rel: 'shortcut icon', href: '/favicon.ico' },
        { rel: 'icon', type: 'image/png', href: '/favicon.png' },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' }
      ]
    }
  },
  colorMode: {
    classSuffix: '',
    preference: 'light',
    fallback: 'light'
  }
})
