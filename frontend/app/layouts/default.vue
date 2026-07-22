<script setup lang="ts">
import SiteFooter from '~/components/layout/SiteFooter.vue'
import SiteHeader from '~/components/layout/SiteHeader.vue'
import { useSiteSettings } from '~/composables/useSiteSettings'

const { settings, loadSiteSettings } = useSiteSettings()

useHead(() => ({
  titleTemplate: title => title ? `${title} - ${settings.value.siteTitle}` : settings.value.siteTitle,
  link: [
    { rel: 'icon', type: 'image/png', href: '/favicon.png' },
    { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' }
  ],
  script: [
    {
      src: '/live2d/live2d.js',
      defer: true,
      tagPosition: 'bodyClose'
    }
  ]
}))

onMounted(loadSiteSettings)
</script>

<template>
  <div class="site-shell text-[rgb(var(--text-primary))]">
    <SiteHeader />
    <main>
      <slot />
    </main>
    <SiteFooter />
  </div>
</template>
