<script setup lang="ts">
import type { ArticleSummary } from '~/types/article'
import { useSiteSettings } from '~/composables/useSiteSettings'

interface TocItem {
  id: string
  text: string
  level: number
}

interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

interface TaxonomyCount {
  name: string
  slug: string
  count: number
}

withDefaults(defineProps<{
  articleCount?: number
  latestPosts?: ArticleSummary[]
  tocItems?: TocItem[]
  activeTocId?: string
}>(), {
  articleCount: 0,
  latestPosts: () => [],
  tocItems: () => [],
  activeTocId: ''
})

const { apiFetch } = useApi()
const { settings, loadSiteSettings } = useSiteSettings()

const categories = ref<TaxonomyCount[]>([
  { name: '编程', slug: 'programming', count: 0 },
  { name: '深度学习', slug: 'deep-learning', count: 0 },
  { name: '名言赏析', slug: 'quote-notes', count: 0 }
])
const tags = ref<TaxonomyCount[]>([])

const loadTaxonomies = async () => {
  try {
    const [categoryResponse, tagResponse] = await Promise.all([
      apiFetch<ApiResponse<TaxonomyCount[]>>('/public/categories'),
      apiFetch<ApiResponse<TaxonomyCount[]>>('/public/tags')
    ])
    categories.value = categoryResponse.data.filter(category => category.count > 0 || category.name)
    tags.value = tagResponse.data.filter(tag => tag.count > 0).slice(0, 16)
  } catch {
    tags.value = []
  }
}

onMounted(async () => {
  await Promise.all([
    loadSiteSettings(),
    loadTaxonomies()
  ])
})
</script>

<template>
  <aside class="butterfly-sidebar">
    <section class="butterfly-card sidebar-profile-card">
      <img
        :src="settings.avatarUrl || '/images/profile-id.webp'"
        :alt="settings.displayName"
        class="sidebar-avatar"
      >
      <h2>{{ settings.displayName }}</h2>
      <p class="sidebar-motto">{{ settings.motto }}</p>
      <div class="sidebar-stats">
        <div>
          <p>文章</p>
          <strong>{{ articleCount }}</strong>
        </div>
        <div>
          <p>标签</p>
          <strong>{{ tags.length }}</strong>
        </div>
        <div>
          <p>分类</p>
          <strong>{{ categories.length }}</strong>
        </div>
      </div>
      <NuxtLink
        to="/about"
        class="sidebar-follow"
      >
        Follow Me
      </NuxtLink>
    </section>

    <section class="butterfly-card sidebar-section">
      <h2>公告</h2>
      <p>{{ settings.announcement }}</p>
      <div class="sidebar-links">
        <span>主站：{{ settings.siteTitle }}</span>
        <span>RSS：{{ settings.rssUrl }}</span>
      </div>
    </section>

    <section v-if="tocItems.length" class="butterfly-card sidebar-section toc-card">
      <h2>目录</h2>
      <a
        v-for="item in tocItems"
        :key="item.id"
        :href="`#${item.id}`"
        class="toc-link"
        :class="[{ active: activeTocId === item.id }, `toc-level-${item.level}`]"
      >
        {{ item.text }}
      </a>
    </section>

    <section class="butterfly-card sidebar-section">
      <h2>最新文章</h2>
      <NuxtLink
        v-for="post in latestPosts"
        :key="post.slug"
        :to="`/articles/${post.slug}`"
        class="latest-post"
      >
        <span
          class="latest-post-cover"
          :style="{ backgroundImage: `url(${post.cover || '/images/henan-wheatfield-bg.png'})` }"
        />
        <span>
          <strong>{{ post.title }}</strong>
          <time :datetime="post.publishedAt">{{ post.publishedAt }}</time>
        </span>
      </NuxtLink>
    </section>

    <section class="butterfly-card sidebar-section">
      <h2>分类</h2>
      <NuxtLink
        v-for="category in categories"
        :key="category.slug"
        to="/categories"
        class="category-row"
      >
        <span>{{ category.name }}</span>
        <strong>{{ category.count }}</strong>
      </NuxtLink>
    </section>

    <section class="butterfly-card sidebar-section">
      <h2>标签</h2>
      <div class="tag-cloud">
        <NuxtLink v-for="tag in tags" :key="tag.slug" to="/search">
          {{ tag.name }}
        </NuxtLink>
      </div>
    </section>

    <section class="butterfly-card sidebar-section site-info">
      <h2>网站信息</h2>
      <div><span>文章数目 :</span><strong>{{ articleCount }}</strong></div>
      <div><span>本站总字数 :</span><strong>146.8k</strong></div>
      <div><span>最后更新 :</span><strong>2026-07-14</strong></div>
    </section>
  </aside>
</template>

