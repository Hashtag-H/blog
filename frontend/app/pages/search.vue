<script setup lang="ts">
import type { ApiResponse, ArticleSummary, PageResponse } from '~/types/article'

interface TaxonomyCount {
  name: string
  slug: string
  count: number
}

useHead({ title: '搜索' })

const { apiFetch } = useApi()
const query = ref('')

const [{ data: articleResponse }, { data: tagResponse }] = await Promise.all([
  useAsyncData('search-page-articles', async () => {
    const response = await apiFetch<ApiResponse<PageResponse<ArticleSummary>>>('/public/articles')
    return response.data.records
  }),
  useAsyncData('search-page-tags', async () => {
    const response = await apiFetch<ApiResponse<TaxonomyCount[]>>('/public/tags')
    return response.data
  })
])

const articles = computed(() => articleResponse.value || [])
const tags = computed(() => (tagResponse.value || []).slice(0, 18))
const results = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  if (!keyword) {
    return articles.value.slice(0, 6)
  }

  return articles.value.filter(article => [
    article.title,
    article.summary,
    article.category,
    ...article.tags
  ].some(value => value.toLowerCase().includes(keyword)))
})
</script>

<template>
  <section class="public-page">
    <header class="public-hero compact">
      <p class="public-kicker">Search</p>
      <h1>搜索</h1>
      <p>输入标题、分类、标签或摘要关键词，快速找到想看的笔记。</p>
    </header>

    <div class="search-panel">
      <input
        v-model="query"
        class="public-search-input"
        placeholder="搜索文章、深度学习、PyTorch、名言..."
        type="search"
      >
      <div class="search-tags">
        <button
          v-for="tag in tags"
          :key="tag.slug"
          type="button"
          @click="query = tag.name"
        >
          # {{ tag.name }}
        </button>
      </div>
    </div>

    <div class="search-results">
      <NuxtLink
        v-for="article in results"
        :key="article.slug"
        :to="`/articles/${article.slug}`"
        class="search-result-card"
      >
        <span
          class="search-result-cover"
          :style="{ backgroundImage: `url(${article.cover || '/images/henan-wheatfield-bg.png'})` }"
        />
        <span>
          <em>{{ article.category }} · {{ article.publishedAt }} · {{ article.readingMinutes }} 分钟</em>
          <strong>{{ article.title }}</strong>
          <small>{{ article.summary }}</small>
        </span>
      </NuxtLink>
      <div v-if="!results.length" class="public-state">没有找到匹配的文章。</div>
    </div>
  </section>
</template>

