<script setup lang="ts">
import { useSiteSettings } from '~/composables/useSiteSettings'

const colorMode = useColorMode()
const { settings, loadSiteSettings } = useSiteSettings()
const isHidden = ref(false)
const lastScrollY = ref(0)

interface NavItem {
  label: string
  to: string
  paths: string[]
  children?: Array<{
    label: string
    to: string
  }>
}

const navItems: NavItem[] = [
  { label: '搜索', to: '/search', paths: ['M21 21l-4.3-4.3', 'M10.5 18a7.5 7.5 0 1 0 0-15 7.5 7.5 0 0 0 0 15Z'] },
  { label: '首页', to: '/', paths: ['M3 11.5 12 4l9 7.5', 'M5.5 10.5V20h13v-9.5', 'M9.5 20v-5h5v5'] },
  {
    label: '博客',
    to: '/articles',
    paths: ['M5 4h10l4 4v12H5V4Z', 'M14 4v5h5', 'M8 13h8M8 16h6'],
    children: [
      { label: '分类', to: '/categories' },
      { label: '标签', to: '/search' },
      { label: '归档', to: '/articles' }
    ]
  },
  { label: '生活', to: '/learning', paths: ['M12 21s7-4.7 7-11A7 7 0 0 0 5 10c0 6.3 7 11 7 11Z', 'M9 10.5h6'] },
  { label: '游戏', to: '/series', paths: ['M7 15h10l1.2 2.4A2 2 0 0 0 22 16.5l-1.6-6.2A4 4 0 0 0 16.5 7h-9a4 4 0 0 0-3.9 3.3L2 16.5a2 2 0 0 0 3.8.9L7 15Z', 'M7.5 11h3M9 9.5v3M15.5 10.5h.01M18 12.5h.01'] },
  { label: '留言板', to: '/about', paths: ['M4 5h16v11H7l-3 3V5Z', 'M8 9h8M8 12h5'] },
  { label: '工具', to: '/search', paths: ['M14.7 6.3a4 4 0 0 0 3 5.2L11.5 17.7a2.4 2.4 0 1 1-3.4-3.4l6.2-6.2a4 4 0 0 0 .4-1.8Z', 'M8.5 15.5l-2 2'] },
  { label: '友链', to: '/categories', paths: ['M10 13a5 5 0 0 0 7.1 0l2-2a5 5 0 0 0-7.1-7.1l-1.1 1.1', 'M14 11a5 5 0 0 0-7.1 0l-2 2a5 5 0 0 0 7.1 7.1l1.1-1.1'] }
]

const toggleTheme = () => {
  colorMode.preference = colorMode.value === 'dark' ? 'light' : 'dark'
}

const handleScroll = () => {
  const currentY = window.scrollY
  const scrollingDown = currentY > lastScrollY.value

  isHidden.value = scrollingDown && currentY > 120
  lastScrollY.value = currentY
}

onMounted(() => {
  loadSiteSettings()
  lastScrollY.value = window.scrollY
  window.addEventListener('scroll', handleScroll, { passive: true })
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<template>
  <header
    class="site-header fixed inset-x-0 top-0 z-30 bg-transparent transition-transform duration-200"
    :class="isHidden ? '-translate-y-full' : 'translate-y-0'"
  >
    <div class="site-header-inner">
      <NuxtLink to="/" class="brand-link">
        <img src="/images/generated/henan-wa-avatar-icon.png" alt="" class="brand-icon">
        {{ settings.siteTitle }}
      </NuxtLink>

      <div class="nav-area">
        <nav class="nav-shell" aria-label="主导航">
          <div
            v-for="item in navItems"
            :key="`${item.label}-${item.to}`"
            class="nav-item"
          >
            <NuxtLink :to="item.to" class="nav-link">
              <svg class="nav-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path
                  v-for="path in item.paths"
                  :key="path"
                  :d="path"
                />
              </svg>
              <span>{{ item.label }}</span>
              <span v-if="item.children?.length" class="nav-caret">⌄</span>
            </NuxtLink>
            <div v-if="item.children?.length" class="nav-dropdown">
              <NuxtLink
                v-for="child in item.children"
                :key="child.to"
                :to="child.to"
              >
                {{ child.label }}
              </NuxtLink>
            </div>
          </div>
        </nav>

        <button
          type="button"
          class="theme-toggle"
          aria-label="切换主题"
          @click="toggleTheme"
        >
          {{ colorMode.value === 'dark' ? '浅色' : '深色' }}
        </button>
      </div>
    </div>
  </header>
</template>
