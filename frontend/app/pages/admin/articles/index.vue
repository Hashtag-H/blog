<script setup lang="ts">
import { useAdminToast } from '~/composables/useAdminToast'

definePageMeta({
  layout: 'admin'
})

useHead({ title: '文章管理' })

interface AdminArticle {
  id: number
  title: string
  slug: string
  summary?: string
  coverUrl?: string
  categoryId?: number | null
  categoryName?: string
  contentMarkdown?: string
  status: 'DRAFT' | 'PUBLISHED'
  wordCount: number
  readingMinutes: number
  publishedAt?: string | null
  createdAt: string
  updatedAt: string
  isTop: boolean
}

interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

interface PageResponse<T> {
  records: T[]
  total: number
}

const { apiFetch } = useApi()
const { showToast } = useAdminToast()
const articles = ref<AdminArticle[]>([])
const loading = ref(false)
const deletingId = ref<number | null>(null)
const errorMessage = ref('')
const successMessage = ref('')
const query = ref('')
const statusFilter = ref<'ALL' | 'PUBLISHED' | 'DRAFT'>('ALL')

const loadArticles = async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    const response = await apiFetch<ApiResponse<PageResponse<AdminArticle>>>('/admin/articles')
    articles.value = response.data.records
  } catch {
    errorMessage.value = '文章加载失败，请确认已经登录'
    showToast({ type: 'error', title: '文章加载失败', message: '请确认后台登录状态后重试。' })
  } finally {
    loading.value = false
  }
}

const filteredArticles = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  return articles.value.filter((article) => {
    const matchesStatus = statusFilter.value === 'ALL' || article.status === statusFilter.value
    const matchesKeyword = !keyword
      || article.title.toLowerCase().includes(keyword)
      || article.slug.toLowerCase().includes(keyword)
      || (article.summary || '').toLowerCase().includes(keyword)
      || (article.categoryName || '').toLowerCase().includes(keyword)

    return matchesStatus && matchesKeyword
  })
})

const publishedCount = computed(() => articles.value.filter(article => article.status === 'PUBLISHED').length)
const draftCount = computed(() => articles.value.filter(article => article.status === 'DRAFT').length)
const topCount = computed(() => articles.value.filter(article => article.isTop).length)

const formatDate = (value?: string | null) => {
  if (!value) {
    return '未发布'
  }

  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(new Date(value))
}

const deleteArticle = async (article: AdminArticle) => {
  const confirmed = window.confirm(`确认删除《${article.title}》吗？删除后前台将不再显示。`)
  if (!confirmed) {
    return
  }

  deletingId.value = article.id
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await apiFetch<ApiResponse<void>>(`/admin/articles/${article.id}`, { method: 'DELETE' })
    articles.value = articles.value.filter(item => item.id !== article.id)
    successMessage.value = '文章已删除'
    showToast({ type: 'success', title: '文章删除成功', message: `《${article.title}》已从列表移除。` })
  } catch {
    errorMessage.value = '删除失败，请稍后再试'
    showToast({ type: 'error', title: '删除失败', message: '请稍后再试。' })
  } finally {
    deletingId.value = null
  }
}

const toggleTop = async (article: AdminArticle) => {
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const response = await apiFetch<ApiResponse<AdminArticle>>(`/admin/articles/${article.id}/top`, {
      method: 'PUT',
      body: { isTop: !article.isTop }
    })
    const next = response.data
    articles.value = articles.value
      .map(item => item.id === article.id ? next : item)
      .sort((a, b) => Number(b.isTop) - Number(a.isTop) || new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
    successMessage.value = next.isTop ? '文章已置顶' : '已取消置顶'
    showToast({
      type: 'success',
      title: next.isTop ? '文章置顶成功' : '已取消置顶',
      message: `《${next.title}》的展示顺序已更新。`
    })
  } catch {
    errorMessage.value = '置顶操作失败，请稍后再试'
    showToast({ type: 'error', title: '置顶操作失败', message: '请稍后再试。' })
  }
}

onMounted(loadArticles)
</script>

<template>
  <section class="admin-page article-admin-page">
    <header class="admin-page-header article-admin-hero">
      <div>
        <p class="admin-kicker">Articles</p>
        <h1>文章管理</h1>
        <p class="admin-page-subtitle">
          管理发布状态、快速编辑内容，并清理不再展示的文章。
        </p>
      </div>
      <div class="admin-header-actions">
        <button type="button" class="admin-secondary-button" :disabled="loading" @click="loadArticles">
          刷新
        </button>
        <NuxtLink to="/admin/articles/new" class="admin-primary-link">
          新建文章
        </NuxtLink>
      </div>
    </header>

    <div class="admin-stat-grid">
      <div class="admin-stat-card">
        <span>全部文章</span>
        <strong>{{ articles.length }}</strong>
      </div>
      <div class="admin-stat-card">
        <span>已发布</span>
        <strong>{{ publishedCount }}</strong>
      </div>
      <div class="admin-stat-card">
        <span>草稿</span>
        <strong>{{ draftCount }}</strong>
      </div>
      <div class="admin-stat-card">
        <span>置顶文章</span>
        <strong>{{ topCount }}</strong>
      </div>
    </div>

    <div class="admin-list-toolbar">
      <label class="admin-search-field">
        <span>搜索</span>
        <input v-model="query" placeholder="标题、slug 或摘要">
      </label>
      <div class="admin-segmented" aria-label="状态筛选">
        <button
          type="button"
          :class="{ active: statusFilter === 'ALL' }"
          @click="statusFilter = 'ALL'"
        >
          全部
        </button>
        <button
          type="button"
          :class="{ active: statusFilter === 'PUBLISHED' }"
          @click="statusFilter = 'PUBLISHED'"
        >
          已发布
        </button>
        <button
          type="button"
          :class="{ active: statusFilter === 'DRAFT' }"
          @click="statusFilter = 'DRAFT'"
        >
          草稿
        </button>
      </div>
    </div>

    <p v-if="loading" class="editor-message">正在加载文章...</p>
    <p v-else-if="errorMessage" class="login-error">{{ errorMessage }}</p>
    <p v-else-if="successMessage" class="editor-message">{{ successMessage }}</p>

    <div class="article-admin-list">
      <article
        v-for="article in filteredArticles"
        :key="article.id"
        :class="['article-admin-card', { pinned: article.isTop }]"
      >
        <NuxtLink
          :to="`/admin/articles/new?id=${article.id}`"
          class="article-admin-cover"
          :style="{ backgroundImage: `url(${article.coverUrl || '/images/henan-wheatfield-bg.png'})` }"
          aria-label="编辑文章"
        />
        <div class="article-admin-body">
          <div class="article-admin-topline">
            <span :class="['admin-status', article.status === 'PUBLISHED' ? 'published' : 'draft']">
              {{ article.status === 'PUBLISHED' ? '已发布' : '草稿' }}
            </span>
            <span v-if="article.isTop" class="article-top-badge">置顶</span>
            <span class="article-category-badge">{{ article.categoryName || '未分类' }}</span>
            <span>{{ formatDate(article.publishedAt || article.updatedAt) }}</span>
          </div>
          <NuxtLink :to="`/admin/articles/new?id=${article.id}`" class="article-admin-title">
            {{ article.title }}
          </NuxtLink>
          <p class="article-admin-slug">{{ article.slug }}</p>
          <p class="article-admin-summary">
            {{ article.summary || '暂无摘要' }}
          </p>
          <div class="article-admin-meta">
            <span>{{ article.wordCount || 0 }} 字</span>
            <span>{{ article.readingMinutes }} 分钟阅读</span>
            <span>更新 {{ formatDate(article.updatedAt) }}</span>
          </div>
        </div>
        <div class="article-admin-actions">
          <NuxtLink :to="`/articles/${article.slug}`" class="admin-secondary-link" target="_blank">
            预览
          </NuxtLink>
          <NuxtLink :to="`/admin/articles/new?id=${article.id}`" class="admin-secondary-link">
            编辑
          </NuxtLink>
          <button
            type="button"
            class="admin-secondary-button compact"
            @click="toggleTop(article)"
          >
            {{ article.isTop ? '取消置顶' : '置顶' }}
          </button>
          <button
            type="button"
            class="admin-danger-button"
            :disabled="deletingId === article.id"
            @click="deleteArticle(article)"
          >
            {{ deletingId === article.id ? '删除中' : '删除' }}
          </button>
        </div>
      </article>

      <div v-if="!loading && !filteredArticles.length" class="admin-empty-state">
        <h2>没有匹配的文章</h2>
        <p>换个关键词或状态筛选试试。</p>
      </div>
    </div>
  </section>
</template>

