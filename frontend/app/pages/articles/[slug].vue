<script setup lang="ts">
import type { ApiResponse, ArticleDetail } from '~/types/article'

interface TocItem {
  id: string
  text: string
  level: number
}

const route = useRoute()
const colorMode = useColorMode()
const { apiFetch } = useApi()

const slug = computed(() => String(route.params.slug || ''))

const fallbackArticle: ArticleDetail = {
  title: 'XDU-STE 研究生生存手册',
  slug: 'xdu-ste-guide',
  summary: '西电通院研究生生存手册，整理课程答案、培养方案、选课、期末、生活事项与实用工具推荐。',
  category: '学习资料',
  tags: ['研究生', '西电', '课程'],
  publishedAt: '2025-07-07',
  readingMinutes: 7,
  cover: '/images/henan-wheatfield-bg.png',
  contentHtml: null,
  contentMarkdown: `前言：本文部分内容因专业和年级差异并不完全通用，请结合官方通知与本专业培养方案判断。

## 一、课程答案

- 西电雨课堂：学术规范与论文写作
- 西电雨课堂：科学道德与学风
- 西电雨课堂：学术交流英语
- 西电雨课堂：工程伦理
- 工程优化方法与人工智能安全伦理相关作业

## 二、培养相关

> 这一部分仅作为经验参考，请以研究生系统、学院通知和导师组要求为准。

### 2.1 培养方案

培养方案会随年级、学院、专业方向发生变化。选课前建议先查看本专业的计划学分、必修课、选修课、公共限选课与必修环节，再决定每学期的课程组合。

1. 政治理论课通常需要完成指定学分。
2. 英语公共课会根据入学英语水平和课程安排分流。
3. 专业核心课和专业课需要注意类别要求，避免只看总学分。
4. 综合素养课、体育、心理健康教育等课程也要预留时间。

### 2.2 选课

先制定培养计划，再进入选课。选课期间建议提前准备好网络环境和多个浏览器，优先确认思政、英语、体育、数学课等容量紧张或时间敏感的课程。

### 2.3 期末

研究生期末与本科阶段相似，但挂科通常需要重修。数学类课程建议留出更完整的复习周期，英语和考查类课程也要注意平时作业与考勤。

## 三、生活相关

1. 入学前留意银行卡、报到须知、宿舍信息、体检和医保等通知。
2. 报到当天通常会涉及缴费确认、证书检查、校园卡领取、体检医保和住宿办理。
3. 宿舍、洗衣、淋浴、直饮水、快递和打印店的位置，可以提前向同门或学长学姐确认。
4. 餐厅、校门、周边商圈和交通路线，开学前熟悉一遍会省下不少时间。

## 四、好物推荐（无恰饭）

### 4.1 软件

- traintime_pda：适合查询课程、成绩、考试等校园信息。
- AXmath：适合公式编辑和论文写作。
- Everything：快速检索本机文件。
- 批量重命名工具：处理数据集、图片和实验结果时很方便。

### 4.2 网站

- 图片公式识别：适合把截图公式转换成 LaTeX。
- AutoDL：适合临时租用算力。
- 西安电子科技大学生存手册：可以参考校园生活经验。
- Netron：查看深度学习模型结构。

## 五、碎碎念

读研期间要重视身心状态，也要尽早想清楚毕业后的方向。信息差会消耗大量时间，能被整理、记录和分享的经验，都可能在某个时刻帮到后来的人。`
}

const escapeHtml = (value: string) => value
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;')

const stripHtml = (value: string) => value.replace(/<[^>]*>/g, '').trim()

const slugifyHeading = (value: string, counts: Record<string, number>) => {
  const base = value
    .toLowerCase()
    .trim()
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '') || 'section'

  counts[base] = (counts[base] || 0) + 1
  return counts[base] === 1 ? base : `${base}-${counts[base]}`
}

const renderInline = (value: string) => {
  let html = escapeHtml(value)
  html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">')
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noreferrer">$1</a>')
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>')
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
  return html
}

const extractTocFromMarkdown = (source: string) => {
  const counts: Record<string, number> = {}
  return source
    .split('\n')
    .map((line) => {
      const match = /^(#{2,3})\s+(.+)$/.exec(line)
      if (!match) {
        return null
      }

      const levelMark = match[1] || ''
      const text = (match[2] || '').trim()
      return {
        id: slugifyHeading(text, counts),
        text,
        level: levelMark.length
      }
    })
    .filter((item): item is TocItem => Boolean(item))
}

const extractTocFromHtml = (source: string) => {
  const counts: Record<string, number> = {}
  const items: TocItem[] = []
  const regex = /<h([2-3])[^>]*>(.*?)<\/h\1>/gi
  let match = regex.exec(source)

  while (match) {
    const text = stripHtml(match[2] || '')
    if (text) {
      items.push({
        id: slugifyHeading(text, counts),
        text,
        level: Number(match[1] || 2)
      })
    }
    match = regex.exec(source)
  }

  return items
}

const renderMarkdown = (source: string) => {
  const lines = source.split('\n')
  const blocks: string[] = []
  const headingCounts: Record<string, number> = {}
  let inCode = false
  let codeBuffer: string[] = []
  let listItems: string[] = []
  let listType: 'ul' | 'ol' | null = null

  const flushList = () => {
    if (listItems.length && listType) {
      blocks.push(`<${listType}>${listItems.join('')}</${listType}>`)
      listItems = []
      listType = null
    }
  }

  for (const line of lines) {
    if (line.startsWith('```')) {
      flushList()
      if (inCode) {
        blocks.push(`<pre><code>${escapeHtml(codeBuffer.join('\n'))}</code></pre>`)
        codeBuffer = []
      }
      inCode = !inCode
      continue
    }

    if (inCode) {
      codeBuffer.push(line)
      continue
    }

    if (!line.trim()) {
      flushList()
      continue
    }

    const unorderedMatch = /^[-*]\s+(.+)$/.exec(line)
    const orderedMatch = /^\d+\.\s+(.+)$/.exec(line)
    if (unorderedMatch || orderedMatch) {
      const nextType = unorderedMatch ? 'ul' : 'ol'
      if (listType && listType !== nextType) {
        flushList()
      }
      listType = nextType
      listItems.push(`<li>${renderInline((unorderedMatch || orderedMatch)?.[1] || '')}</li>`)
      continue
    }

    flushList()
    const headingMatch = /^(#{1,3})\s+(.+)$/.exec(line)
    if (headingMatch) {
      const level = (headingMatch[1] || '').length
      const text = (headingMatch[2] || '').trim()
      const id = level > 1 ? ` id="${slugifyHeading(text, headingCounts)}"` : ''
      blocks.push(`<h${level}${id}>${renderInline(text)}</h${level}>`)
    } else if (/^>\s+/.test(line)) {
      blocks.push(`<blockquote>${renderInline(line.replace(/^>\s+/, ''))}</blockquote>`)
    } else {
      blocks.push(`<p>${renderInline(line)}</p>`)
    }
  }

  flushList()
  if (inCode && codeBuffer.length) {
    blocks.push(`<pre><code>${escapeHtml(codeBuffer.join('\n'))}</code></pre>`)
  }

  return blocks.join('')
}

const addHeadingIds = (source: string) => {
  const counts: Record<string, number> = {}
  return source.replace(/<h([2-3])([^>]*)>(.*?)<\/h\1>/gi, (full, level, attrs, content) => {
    if (/\sid=/.test(attrs)) {
      return full
    }

    const text = stripHtml(content)
    return `<h${level}${attrs} id="${slugifyHeading(text, counts)}">${content}</h${level}>`
  })
}

const { data, pending } = await useAsyncData(`article-${slug.value}`, async () => {
  try {
    const response = await apiFetch<ApiResponse<ArticleDetail>>(`/public/articles/${encodeURIComponent(slug.value)}`)
    return response.data
  } catch {
    return slug.value === fallbackArticle.slug ? fallbackArticle : null
  }
})

const article = computed(() => data.value)
const tocItems = computed(() => {
  if (!article.value) {
    return []
  }

  if (article.value.contentMarkdown) {
    return extractTocFromMarkdown(article.value.contentMarkdown)
  }

  return extractTocFromHtml(article.value.contentHtml || '')
})
const renderedContent = computed(() => {
  if (!article.value) {
    return ''
  }

  if (article.value.contentHtml) {
    return addHeadingIds(article.value.contentHtml)
  }

  return renderMarkdown(article.value.contentMarkdown || '')
})

const wordCount = computed(() => {
  const text = article.value?.contentMarkdown || stripHtml(article.value?.contentHtml || '')
  const cjkCount = (text.match(/[\u4e00-\u9fff]/g) || []).length
  const wordCount = (text.replace(/[\u4e00-\u9fff]/g, ' ').match(/\b[\w-]+\b/g) || []).length
  return cjkCount + wordCount
})

const formattedWordCount = computed(() => {
  if (wordCount.value >= 1000) {
    return `${(wordCount.value / 1000).toFixed(1)}k`
  }
  return String(wordCount.value)
})

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const toggleTheme = () => {
  colorMode.preference = colorMode.value === 'dark' ? 'light' : 'dark'
}

useHead(() => ({
  title: article.value?.title || slug.value,
  meta: article.value?.summary
    ? [{ name: 'description', content: article.value.summary }]
    : []
}))
</script>

<template>
  <div class="article-page">
    <section class="article-content-band">
      <div class="article-layout" :class="{ 'article-layout-full': !tocItems.length }">
        <aside v-if="tocItems.length" class="butterfly-card article-toc-sidebar" aria-label="文章目录">
          <h2>目录</h2>
          <a
            v-for="item in tocItems"
            :key="item.id"
            :href="`#${item.id}`"
            class="article-toc-link"
            :class="`toc-level-${item.level}`"
          >
            {{ item.text }}
          </a>
        </aside>

        <main class="article-main">
          <article v-if="pending" class="butterfly-card butterfly-article article-state">
            数据加载中
          </article>

          <article v-else-if="!article" class="butterfly-card butterfly-article article-state">
            <h1>Article not found</h1>
            <p>文章可能尚未发布，或者链接不正确。</p>
            <NuxtLink to="/" class="article-inline-link">返回首页</NuxtLink>
          </article>

          <article v-else class="butterfly-card butterfly-article">
            <header class="article-header-block">
              <NuxtLink to="/" class="article-home-link">返回首页</NuxtLink>
              <h1>{{ article.title }}</h1>
              <p class="article-meta-line">
                发表于 {{ article.publishedAt }} | 更新于 2026-06-10
              </p>
              <p class="article-meta-line">
                | 总字数: {{ formattedWordCount }} | 阅读时长: {{ article.readingMinutes }} 分钟 | 评论数:
              </p>
              <p v-if="article.summary" class="article-summary">
                {{ article.summary }}
              </p>
              <div v-if="article.tags?.length" class="article-tag-row">
                <span v-for="tag in article.tags" :key="tag"># {{ tag }}</span>
              </div>
            </header>

            <div class="article-content" v-html="renderedContent" />

            <footer class="article-license">
              <p><strong>文章作者:</strong> <NuxtLink to="/about">河南娃</NuxtLink></p>
              <p><strong>文章链接:</strong> <NuxtLink :to="`/articles/${article.slug}`">/articles/{{ article.slug }}</NuxtLink></p>
              <p><strong>版权声明:</strong> 本博客所有文章除特别声明外，均采用 CC BY-NC-SA 4.0 许可协议。转载请注明来源。</p>
            </footer>

            <section class="article-comments-placeholder">
              <h2>评论</h2>
              <p>评论区准备中。</p>
            </section>
          </article>
        </main>

      </div>
    </section>

    <div class="rightside-tools">
      <button type="button" aria-label="回到顶部" title="回到顶部" @click="scrollToTop">
        ↑
      </button>
      <button type="button" aria-label="切换主题" title="切换主题" @click="toggleTheme">
        ◐
      </button>
    </div>
  </div>
</template>

