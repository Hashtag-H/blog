<script setup lang="ts">
import type { ApiResponse, ArticleSummary, PageResponse } from '~/types/article'

useHead({
  title: '文章'
})

const { apiFetch } = useApi()

const { data, pending, error } = await useAsyncData('articles-page', async () => {
  const response = await apiFetch<ApiResponse<PageResponse<ArticleSummary>>>('/public/articles')
  return response.data.records
})

const articles = computed(() => data.value || [])
const featured = computed(() => articles.value[0])
const archiveGroups = computed(() => {
  const groups = new Map<string, ArticleSummary[]>()
  for (const article of articles.value) {
    const year = article.publishedAt?.slice(0, 4) || '未发布'
    groups.set(year, [...(groups.get(year) || []), article])
  }
  return Array.from(groups.entries()).map(([year, records]) => ({ year, records }))
})
</script>

<template>
  <section class="public-page">
    <header class="public-hero compact">
      <p class="public-kicker">Archive</p>
      <h1>文章归档</h1>
      <p>把编程、深度学习、读书和生活里的笔记收在这里。慢慢读，不赶路。</p>
    </header>

    <div v-if="pending" class="public-state">正在加载文章...</div>
    <div v-else-if="error" class="public-state">文章加载失败，请确认后端服务正在运行。</div>
    <div v-else-if="!articles.length" class="public-state">还没有已发布文章。</div>

    <div v-else class="archive-layout">
      <NuxtLink
        v-if="featured"
        :to="`/articles/${featured.slug}`"
        class="archive-feature"
      >
        <span
          class="archive-feature-cover"
          :style="{ backgroundImage: `url(${featured.cover || '/images/henan-wheatfield-bg.png'})` }"
        />
        <span class="archive-feature-body">
          <span class="post-card-category">{{ featured.category }}</span>
          <strong>{{ featured.title }}</strong>
          <em>{{ featured.summary }}</em>
          <span class="archive-feature-meta">{{ featured.publishedAt }} · {{ featured.readingMinutes }} 分钟阅读</span>
        </span>
      </NuxtLink>

      <div class="archive-timeline">
        <section
          v-for="group in archiveGroups"
          :key="group.year"
          class="archive-year"
        >
          <h2>{{ group.year }}</h2>
          <NuxtLink
            v-for="article in group.records"
            :key="article.slug"
            :to="`/articles/${article.slug}`"
            class="archive-row"
          >
            <time :datetime="article.publishedAt">{{ article.publishedAt.slice(5) }}</time>
            <span>
              <strong>{{ article.title }}</strong>
              <em>{{ article.category }} · {{ article.readingMinutes }} 分钟</em>
            </span>
          </NuxtLink>
        </section>
      </div>
    </div>
  </section>
</template>

