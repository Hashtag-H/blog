<script setup lang="ts">
import ProfileSidebar from '~/components/layout/ProfileSidebar.vue'
import type { ApiResponse, ArticleSummary, PageResponse } from '~/types/article'

useHead({
  title: '河南娃的小窝'
})

const colorMode = useColorMode()
const route = useRoute()
const { apiFetch } = useApi()
const showSidebar = ref(true)
const heroSubtitleText = '愿麦浪祝颂你的旅途'
const heroSubtitleChars = heroSubtitleText.split('')
const homePageSize = 5

const fallbackPosts: ArticleSummary[] = [
  {
    title: 'XDU-STE 研究生生存手册',
    slug: 'xdu-ste-guide',
    publishedAt: '2025-07-07',
    category: '学习资料',
    tags: ['研究生', '西电', '课程'],
    readingMinutes: 12,
    cover: '/images/henan-wheatfield-bg.png',
    summary: '西电通院研究生生存手册，包含课程资料、培养相关、选课、期末、生活相关、好物推荐等内容。'
  },
  {
    title: '西电 - 网络信息论知识清单',
    slug: 'network-information-theory-list',
    publishedAt: '2026-06-25',
    category: '网络信息论',
    tags: ['信息论', '复习', '通信'],
    readingMinutes: 18,
    cover: '/images/sakura-bg.jpg',
    summary: '整理熵与互信息、典型序列、信道容量、多址接入、广播信道、相关信源编码、中继信道和干扰信道等核心知识。'
  },
  {
    title: 'Live2D AI 聊天功能配置教程',
    slug: 'live2d-ai-chat',
    publishedAt: '2026-02-27',
    category: 'AI 实践',
    tags: ['Live2D', 'FastAPI', 'DeepSeek'],
    readingMinutes: 9,
    cover: '/images/sakura-bg.jpg',
    summary: '介绍如何部署支持上下文对话、Markdown 渲染和全站检索的 AI 博客伴侣。'
  },
  {
    title: '西电 - 网络信息论 第一章：引言与回顾',
    slug: 'network-information-theory-chapter-1',
    publishedAt: '2026-06-24',
    category: '网络信息论',
    tags: ['熵', '互信息', '典型序列'],
    readingMinutes: 14,
    cover: '/images/henan-wheatfield-bg.png',
    summary: '课程概述、信息论基础、熵与互信息、典型序列、信源编码、信道容量和 MIMO 信道等内容的学习笔记。'
  },
  {
    title: 'AI 驱动的个人知识博客与学习管理平台',
    slug: 'ai-knowledge-blog',
    publishedAt: '2026-07-14',
    category: '项目开发',
    tags: ['全栈', '知识库', '学习管理'],
    readingMinutes: 10,
    cover: '/images/sakura-bg.jpg',
    summary: '一个用于写作、知识管理、智能延伸阅读和学习计划管理的个人博客平台。'
  }
]

const currentPage = computed(() => {
  const value = Number(route.query.page || 1)
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : 1
})

const { data: articleResponse, pending } = await useAsyncData('home-articles', async () => {
  try {
    return await apiFetch<ApiResponse<PageResponse<ArticleSummary>>>(
      `/public/articles?page=${currentPage.value}&pageSize=${homePageSize}`
    )
  } catch {
    return null
  }
}, {
  watch: [currentPage]
})

const fallbackPagePosts = computed(() => {
  const start = (currentPage.value - 1) * homePageSize
  return fallbackPosts.slice(start, start + homePageSize)
})

const posts = computed(() => {
  return articleResponse.value?.data?.records?.length
    ? articleResponse.value.data.records
    : fallbackPagePosts.value
})

const totalArticles = computed(() => articleResponse.value?.data?.total || fallbackPosts.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalArticles.value / homePageSize)))

const paginationItems = computed<(number | 'ellipsis')[]>(() => {
  const total = totalPages.value
  const page = Math.min(currentPage.value, total)

  if (total <= 7) {
    return Array.from({ length: total }, (_, index) => index + 1)
  }

  const items: (number | 'ellipsis')[] = [1]
  const start = Math.max(2, page - 1)
  const end = Math.min(total - 1, page + 1)

  if (start > 2) {
    items.push('ellipsis')
  }

  for (let index = start; index <= end; index += 1) {
    items.push(index)
  }

  if (end < total - 1) {
    items.push('ellipsis')
  }

  items.push(total)
  return items
})

const formatDate = (date: string) => date

const pageLink = (page: number) => {
  const safePage = Math.min(Math.max(page, 1), totalPages.value)
  return safePage === 1 ? '/' : { path: '/', query: { page: safePage } }
}

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const toggleTheme = () => {
  colorMode.preference = colorMode.value === 'dark' ? 'light' : 'dark'
}
</script>

<template>
  <div>
    <section class="home-hero">
      <div class="home-hero-content">
        <h1 class="home-hero-title">河南娃的小窝</h1>
        <p class="home-hero-subtitle" :aria-label="heroSubtitleText">
          <span
            v-for="(char, index) in heroSubtitleChars"
            :key="`${char}-${index}`"
            class="subtitle-char"
            :style="{ animationDelay: `${index * 0.1}s` }"
          >
            {{ char }}
          </span>
        </p>
      </div>
      <div class="home-hero-arrow">⌄</div>
    </section>

    <section class="home-content-band">
      <div class="home-layout" :class="{ 'home-layout-full': !showSidebar }">
        <div class="home-feed">
          <div v-if="pending" class="home-loading-state">
            正在翻找麦田里的笔记...
          </div>

          <div v-else-if="!posts.length" class="home-loading-state">
            这一页暂时没有文章。
          </div>

          <div v-else class="post-directory">
            <NuxtLink
              v-for="post in posts"
              :key="post.slug"
              :to="`/articles/${post.slug}`"
              :class="['post-card', { 'post-card-pinned': post.isTop }]"
            >
              <div class="post-card-media">
                <span v-if="post.isTop" class="post-card-pin">置顶</span>
                <div
                  class="post-card-cover"
                  :style="{ backgroundImage: `url(${post.cover || '/images/henan-wheatfield-bg.png'})` }"
                />
              </div>
              <div class="post-card-body">
                <div class="post-card-category">
                  <span>{{ post.isTop ? '📌' : '◆' }}</span>
                  {{ post.category }}
                  <em v-if="post.isTop">优先推荐</em>
                </div>
                <h2 class="post-card-title">{{ post.title }}</h2>
                <p class="post-card-meta">
                  发表于 {{ formatDate(post.publishedAt) }}
                  <span v-if="post.category">| {{ post.category }}</span>
                </p>
                <p class="post-card-summary">{{ post.summary }}</p>
                <div class="post-card-tags">
                  <span v-for="tag in post.tags" :key="tag"># {{ tag }}</span>
                </div>
              </div>
            </NuxtLink>
          </div>

          <nav v-if="totalPages > 1" class="home-pagination" aria-label="分页">
            <NuxtLink
              :to="pageLink(currentPage - 1)"
              :class="{ disabled: currentPage <= 1 }"
              :aria-disabled="currentPage <= 1"
            >
              上一页
            </NuxtLink>
            <template v-for="(item, index) in paginationItems" :key="`${item}-${index}`">
              <span v-if="item === 'ellipsis'" class="ellipsis">...</span>
              <NuxtLink
                v-else
                :to="pageLink(item)"
                :class="{ active: item === currentPage }"
                :aria-current="item === currentPage ? 'page' : undefined"
              >
                {{ item }}
              </NuxtLink>
            </template>
            <NuxtLink
              :to="pageLink(currentPage + 1)"
              :class="{ disabled: currentPage >= totalPages }"
              :aria-disabled="currentPage >= totalPages"
            >
              下一页
            </NuxtLink>
          </nav>
        </div>

        <ProfileSidebar
          v-if="showSidebar"
          :article-count="totalArticles"
          :latest-posts="posts.slice(0, 5)"
        />
      </div>
    </section>

    <div class="rightside-tools">
      <button type="button" aria-label="回到顶部" title="回到顶部" @click="scrollToTop">
        ↑
      </button>
      <button type="button" aria-label="切换主题" title="切换主题" @click="toggleTheme">
        ◐
      </button>
      <button
        type="button"
        aria-label="显示或隐藏侧栏"
        title="显示或隐藏侧栏"
        :class="{ active: showSidebar }"
        @click="showSidebar = !showSidebar"
      >
        ☰
      </button>
    </div>
  </div>
</template>

