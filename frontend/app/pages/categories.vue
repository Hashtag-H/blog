<script setup lang="ts">
import type { ApiResponse, ArticleSummary, PageResponse } from '~/types/article'

interface TaxonomyCount {
  name: string
  slug: string
  count: number
}

useHead({ title: '分类' })

const { apiFetch } = useApi()

const [{ data: categoryResponse }, { data: articleResponse }] = await Promise.all([
  useAsyncData('category-page-categories', async () => {
    const response = await apiFetch<ApiResponse<TaxonomyCount[]>>('/public/categories')
    return response.data
  }),
  useAsyncData('category-page-articles', async () => {
    const response = await apiFetch<ApiResponse<PageResponse<ArticleSummary>>>('/public/articles')
    return response.data.records
  })
])

const articles = computed(() => articleResponse.value || [])
const categories = computed(() => (categoryResponse.value || [])
  .map(category => ({
    ...category,
    articles: articles.value.filter(article => article.category === category.name).slice(0, 3)
  }))
  .filter(category => category.count > 0 || category.articles.length))

const total = computed(() => categories.value.reduce((sum, category) => sum + category.count, 0))
</script>

<template>
  <section class="public-page">
    <header class="public-hero compact">
      <p class="public-kicker">Categories</p>
      <h1>分类</h1>
      <p>按主题重新整理文章脉络。当前共 {{ categories.length }} 个分类，{{ total }} 篇文章。</p>
    </header>

    <div class="taxonomy-grid">
      <article
        v-for="category in categories"
        :key="category.slug"
        class="taxonomy-card"
      >
        <div class="taxonomy-card-head">
          <span>{{ category.name.slice(0, 1) }}</span>
          <div>
            <h2>{{ category.name }}</h2>
            <p>{{ category.count }} 篇文章</p>
          </div>
        </div>
        <div class="taxonomy-posts">
          <NuxtLink
            v-for="article in category.articles"
            :key="article.slug"
            :to="`/articles/${article.slug}`"
          >
            {{ article.title }}
          </NuxtLink>
          <NuxtLink v-if="!category.articles.length" to="/articles">
            暂无公开文章，去归档页看看
          </NuxtLink>
        </div>
      </article>

      <div v-if="!categories.length" class="public-state">还没有可展示的分类。</div>
    </div>
  </section>
</template>
