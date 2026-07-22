<script setup lang="ts">
import { useAdminToast } from '~/composables/useAdminToast'

definePageMeta({
  layout: 'admin'
})

useHead({ title: '文章编辑' })

interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

interface UploadedAsset {
  originalFilename: string
  storedFilename: string
  url: string
  size: number
}

interface AdminCategory {
  id: number
  name: string
  slug: string
  description?: string
  sort: number
  articleCount: number
}

interface AdminArticle {
  id: number
  title: string
  slug: string
  summary?: string
  coverUrl?: string
  categoryId?: number | null
  categoryName?: string
  contentMarkdown: string
  status: 'DRAFT' | 'PUBLISHED'
  isTop: boolean
  tags: string[]
}

const route = useRoute()
const { apiFetch } = useApi()
const { showToast } = useAdminToast()

const title = ref('')
const slug = ref('')
const summary = ref('')
const coverUrl = ref('')
const categoryId = ref<number | ''>('')
const autoCategory = ref(true)
const tagsText = ref('')
const status = ref<'DRAFT' | 'PUBLISHED'>('DRAFT')
const isTop = ref(false)
const markdown = ref(`# 新文章标题

在这里开始写你的 Markdown。

## 小节

- 支持上传 .md 文件
- 支持上传图片并插入
- 支持上传包含图片的本地文件夹，并自动替换 Markdown 图片路径
`)
const saving = ref(false)
const deleting = ref(false)
const uploadMessage = ref('')
const errorMessage = ref('')
const editorRef = ref<HTMLTextAreaElement | null>(null)
const previewEditableRef = ref<HTMLElement | null>(null)
const previewEditMode = ref(true)
const uploadingImages = ref(false)
const isDraggingImages = ref(false)
const categories = ref<AdminCategory[]>([])

const articleId = computed(() => route.query.id ? Number(route.query.id) : null)

const tags = computed(() => tagsText.value.split(/[,，\n]/).map(tag => tag.trim()).filter(Boolean))
const previewHtml = computed(() => renderMarkdown(markdown.value))
const editorStats = computed(() => {
  const text = markdown.value || ''
  const cjkCount = (text.match(/[\u4e00-\u9fff]/g) || []).length
  const wordCount = (text.replace(/[\u4e00-\u9fff]/g, ' ').match(/\b[\w-]+\b/g) || []).length
  const imageCount = (text.match(/!\[[^\]]*]\([^)]+\)/g) || []).length
  const headingCount = (text.match(/^#{1,6}\s+/gm) || []).length

  return {
    words: cjkCount + wordCount,
    images: imageCount,
    headings: headingCount,
    minutes: Math.max(1, Math.ceil((cjkCount + wordCount) / 300))
  }
})

const loadCategories = async () => {
  const response = await apiFetch<ApiResponse<AdminCategory[]>>('/admin/categories')
  categories.value = response.data
}

onMounted(async () => {
  try {
    await loadCategories()
  } catch {
    errorMessage.value = '分类加载失败，请确认已经登录'
    showToast({ type: 'error', title: '分类加载失败', message: '请确认后台登录状态后重试。' })
  }

  if (!articleId.value) {
    return
  }

  try {
    const response = await apiFetch<ApiResponse<AdminArticle>>(`/admin/articles/${articleId.value}`)
    const article = response.data
    title.value = article.title
    slug.value = article.slug
    summary.value = article.summary || ''
    coverUrl.value = article.coverUrl || ''
    categoryId.value = article.categoryId || ''
    autoCategory.value = !article.categoryId
    markdown.value = article.contentMarkdown
    status.value = article.status
    isTop.value = article.isTop
    tagsText.value = article.tags.join(', ')
  } catch {
    errorMessage.value = '文章加载失败，请返回列表重试'
    showToast({ type: 'error', title: '文章加载失败', message: '请返回列表重新打开。' })
  }
})

const saveArticle = async (nextStatus: 'DRAFT' | 'PUBLISHED') => {
  syncPreviewEdits()
  saving.value = true
  status.value = nextStatus
  errorMessage.value = ''
  uploadMessage.value = ''
  try {
    const payload = {
      title: title.value,
      slug: slug.value,
      summary: summary.value,
      coverUrl: coverUrl.value,
      categoryId: categoryId.value || null,
      autoCategory: autoCategory.value,
      contentMarkdown: markdown.value,
      status: nextStatus,
      isTop: isTop.value,
      tags: tags.value
    }
    const url = articleId.value ? `/admin/articles/${articleId.value}` : '/admin/articles'
    const method = articleId.value ? 'PUT' : 'POST'
    const response = await apiFetch<ApiResponse<AdminArticle>>(url, { method, body: payload })
    if (!articleId.value) {
      await navigateTo(`/admin/articles/new?id=${response.data.id}`)
    }
    uploadMessage.value = nextStatus === 'PUBLISHED' ? '文章已发布' : '草稿已保存'
    showToast({
      type: 'success',
      title: nextStatus === 'PUBLISHED' ? '文章发布成功' : '草稿保存成功',
      message: nextStatus === 'PUBLISHED' ? '前台会按发布状态展示这篇文章。' : '你可以稍后继续编辑。'
    })
  } catch {
    errorMessage.value = '保存失败，请检查标题、正文或登录状态'
    showToast({ type: 'error', title: '保存失败', message: '请检查标题、正文或登录状态。' })
  } finally {
    saving.value = false
  }
}

const deleteCurrentArticle = async () => {
  if (!articleId.value) {
    return
  }

  const confirmed = window.confirm(`确认删除《${title.value || '当前文章'}》吗？删除后前台将不再显示。`)
  if (!confirmed) {
    return
  }

  deleting.value = true
  errorMessage.value = ''
  uploadMessage.value = ''
  try {
    await apiFetch<ApiResponse<void>>(`/admin/articles/${articleId.value}`, { method: 'DELETE' })
    showToast({ type: 'success', title: '文章删除成功', message: '前台将不再展示这篇文章。' })
    await navigateTo('/admin/articles')
  } catch {
    errorMessage.value = '删除失败，请稍后再试'
    showToast({ type: 'error', title: '删除失败', message: '请稍后再试。' })
  } finally {
    deleting.value = false
  }
}

const onMarkdownSelected = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) {
    return
  }

  markdown.value = await file.text()
  if (!title.value) {
    title.value = file.name.replace(/\.(md|markdown)$/i, '')
  }
  uploadMessage.value = `已导入 ${file.name}`
  showToast({ type: 'success', title: 'Markdown 导入成功', message: file.name })
  input.value = ''
}

const onImagesSelected = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const files = Array.from(input.files || []).filter(file => file.type.startsWith('image/'))
  try {
    await uploadImagesAndInsert(files)
  } catch {
    errorMessage.value = '图片上传失败，请稍后再试'
    showToast({ type: 'error', title: '图片上传失败', message: '请检查图片格式或登录状态。' })
  } finally {
    input.value = ''
  }
}

const onCoverSelected = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = Array.from(input.files || []).find(item => item.type.startsWith('image/'))
  if (!file) {
    return
  }

  try {
    const uploaded = await uploadImages([file])
    if (uploaded[0]) {
      coverUrl.value = uploaded[0].url
      uploadMessage.value = `封面已设置为 ${file.name}`
      showToast({ type: 'success', title: '封面上传成功', message: file.name })
    }
  } catch {
    errorMessage.value = '封面上传失败，请稍后再试'
    showToast({ type: 'error', title: '封面上传失败', message: '请检查图片格式或登录状态。' })
  } finally {
    input.value = ''
  }
}

const onEditorPaste = async (event: ClipboardEvent) => {
  const files = Array.from(event.clipboardData?.files || []).filter(file => file.type.startsWith('image/'))
  if (!files.length) {
    return
  }

  event.preventDefault()
  try {
    await uploadImagesAndInsert(files)
  } catch {
    errorMessage.value = '粘贴图片上传失败，请稍后再试'
    showToast({ type: 'error', title: '粘贴图片失败', message: '请检查图片格式或登录状态。' })
  }
}

const onEditorDrop = async (event: DragEvent) => {
  isDraggingImages.value = false
  const files = Array.from(event.dataTransfer?.files || []).filter(file => file.type.startsWith('image/'))
  if (!files.length) {
    return
  }

  event.preventDefault()
  try {
    await uploadImagesAndInsert(files)
  } catch {
    errorMessage.value = '拖拽图片上传失败，请稍后再试'
    showToast({ type: 'error', title: '拖拽图片失败', message: '请检查图片格式或登录状态。' })
  }
}

const onEditorDragOver = (event: DragEvent) => {
  if (Array.from(event.dataTransfer?.items || []).some(item => item.kind === 'file')) {
    event.preventDefault()
    isDraggingImages.value = true
  }
}

const onEditorDragLeave = () => {
  isDraggingImages.value = false
}

const onFolderSelected = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const files = Array.from(input.files || [])
  const markdownFile = files.find(file => /\.(md|markdown)$/i.test(file.name))
  if (markdownFile) {
    markdown.value = await markdownFile.text()
    if (!title.value) {
      title.value = markdownFile.name.replace(/\.(md|markdown)$/i, '')
    }
  }

  const images = files.filter(file => file.type.startsWith('image/'))
  try {
    const uploaded = await uploadImages(images)
    markdown.value = replaceLocalImagePaths(markdown.value, uploaded)
    if (!coverUrl.value && uploaded[0]) {
      coverUrl.value = uploaded[0].url
    }
    uploadMessage.value = `已处理 ${images.length} 张图片${markdownFile ? '，并导入 Markdown' : ''}`
    showToast({ type: 'success', title: '文件夹导入完成', message: `已处理 ${images.length} 张图片。` })
  } catch {
    errorMessage.value = '文件夹导入失败，请稍后再试'
    showToast({ type: 'error', title: '文件夹导入失败', message: '请检查图片文件或登录状态。' })
  }
  input.value = ''
}

const uploadImagesAndInsert = async (files: File[]) => {
  if (!files.length) {
    return
  }

  uploadingImages.value = true
  errorMessage.value = ''
  uploadMessage.value = '图片上传中...'
  try {
    const uploaded = await uploadImages(files)
    for (const asset of uploaded) {
      insertAtCursor(`![${asset.originalFilename}](${asset.url})\n`)
    }
    if (!coverUrl.value && uploaded[0]) {
      coverUrl.value = uploaded[0].url
    }
    uploadMessage.value = `已上传 ${uploaded.length} 张图片`
    showToast({ type: 'success', title: '图片上传成功', message: `已上传 ${uploaded.length} 张图片。` })
  } finally {
    uploadingImages.value = false
  }
}

const uploadImages = async (files: File[]) => {
  const uploaded: UploadedAsset[] = []
  for (const file of files) {
    const formData = new FormData()
    formData.append('file', file)
    const response = await apiFetch<ApiResponse<UploadedAsset>>('/admin/uploads/images', {
      method: 'POST',
      body: formData
    })
    uploaded.push({ ...response.data, originalFilename: file.name })
  }
  return uploaded
}

const replaceLocalImagePaths = (source: string, uploaded: UploadedAsset[]) => {
  const byName = new Map(uploaded.map(asset => [asset.originalFilename.toLowerCase(), asset.url]))
  return source.replace(/!\[([^\]]*)\]\((?!https?:|data:|\/api\/)([^)]+)\)/g, (full, alt, rawPath) => {
    const cleanPath = rawPath.replace(/^['"]|['"]$/g, '').split(/[\\/]/).pop()?.toLowerCase()
    const url = cleanPath ? byName.get(cleanPath) : undefined
    return url ? `![${alt}](${url})` : full
  })
}

const insertAtCursor = (text: string) => {
  if (previewEditMode.value) {
    syncPreviewEdits()
    markdown.value += `\n${text}`
    nextTick(() => previewEditableRef.value?.focus())
    return
  }

  const editor = editorRef.value
  if (!editor) {
    markdown.value += `\n${text}`
    return
  }

  const start = editor.selectionStart
  const end = editor.selectionEnd
  markdown.value = `${markdown.value.slice(0, start)}${text}${markdown.value.slice(end)}`
  nextTick(() => {
    editor.focus()
    editor.selectionStart = start + text.length
    editor.selectionEnd = start + text.length
  })
}

const replaceSelection = (formatter: (selected: string) => string) => {
  if (previewEditMode.value) {
    syncPreviewEdits()
    markdown.value += `\n${formatter('')}`
    nextTick(() => previewEditableRef.value?.focus())
    return
  }

  const editor = editorRef.value
  if (!editor) {
    markdown.value += formatter('')
    return
  }

  const start = editor.selectionStart
  const end = editor.selectionEnd
  const selected = markdown.value.slice(start, end)
  const next = formatter(selected)
  markdown.value = `${markdown.value.slice(0, start)}${next}${markdown.value.slice(end)}`
  nextTick(() => {
    editor.focus()
    editor.selectionStart = start
    editor.selectionEnd = start + next.length
  })
}

const applyEditorTool = (tool: 'h2' | 'h3' | 'bold' | 'quote' | 'code' | 'list' | 'divider' | 'image') => {
  if (previewEditMode.value && applyVisualEditorTool(tool)) {
    return
  }

  if (tool === 'h2') {
    replaceSelection(value => `## ${value || '小标题'}`)
  } else if (tool === 'h3') {
    replaceSelection(value => `### ${value || '小节标题'}`)
  } else if (tool === 'bold') {
    replaceSelection(value => `**${value || '重点文字'}**`)
  } else if (tool === 'quote') {
    replaceSelection(value => `> ${value || '引用内容'}`)
  } else if (tool === 'code') {
    replaceSelection(value => value.includes('\n') ? `\`\`\`\n${value}\n\`\`\`` : `\`${value || 'code'}\``)
  } else if (tool === 'list') {
    replaceSelection(value => (value || '列表项').split('\n').map(line => `- ${line}`).join('\n'))
  } else if (tool === 'divider') {
    insertAtCursor('\n---\n')
  } else if (tool === 'image') {
    insertAtCursor('![图片描述](图片地址)\n')
  }
}

const applyVisualEditorTool = (tool: 'h2' | 'h3' | 'bold' | 'quote' | 'code' | 'list' | 'divider' | 'image') => {
  const editor = previewEditableRef.value
  if (!editor || !import.meta.client) {
    return false
  }

  editor.focus()
  if (tool === 'h2') {
    document.execCommand('formatBlock', false, 'h2')
  } else if (tool === 'h3') {
    document.execCommand('formatBlock', false, 'h3')
  } else if (tool === 'bold') {
    document.execCommand('bold')
  } else if (tool === 'quote') {
    document.execCommand('formatBlock', false, 'blockquote')
  } else if (tool === 'code') {
    document.execCommand('formatBlock', false, 'pre')
  } else if (tool === 'list') {
    document.execCommand('insertUnorderedList')
  } else if (tool === 'divider') {
    document.execCommand('insertHorizontalRule')
  } else if (tool === 'image') {
    document.execCommand('insertHTML', false, '<p><img src="图片地址" alt="图片描述"></p>')
  }

  syncPreviewEdits()
  return true
}

const useFirstMarkdownImageAsCover = () => {
  const match = /!\[[^\]]*]\(([^)]+)\)/.exec(markdown.value)
  if (!match?.[1]) {
    showToast({ type: 'error', title: '没有找到正文图片', message: '先上传或插入一张图片，再设为封面。' })
    return
  }
  coverUrl.value = match[1]
  uploadMessage.value = '已使用正文第一张图片作为封面'
  showToast({ type: 'success', title: '封面已更新', message: '已使用正文第一张图片。' })
}

const syncPreviewEdits = () => {
  if (!previewEditableRef.value) {
    return
  }
  markdown.value = htmlToMarkdown(previewEditableRef.value.innerHTML)
}

const toggleEditorMode = () => {
  if (previewEditMode.value) {
    syncPreviewEdits()
  }
  previewEditMode.value = !previewEditMode.value
  nextTick(() => {
    if (previewEditMode.value) {
      previewEditableRef.value?.focus()
    } else {
      editorRef.value?.focus()
    }
  })
}

const htmlToMarkdown = (html: string) => {
  if (!import.meta.client) {
    return markdown.value
  }

  const template = document.createElement('template')
  template.innerHTML = html
  return Array.from(template.content.childNodes)
    .map(nodeToMarkdown)
    .map(block => block.trim())
    .filter(Boolean)
    .join('\n\n')
}

const childrenToMarkdown = (node: Node) => Array.from(node.childNodes).map(inlineNodeToMarkdown).join('')

const inlineNodeToMarkdown = (node: Node): string => {
  if (node.nodeType === Node.TEXT_NODE) {
    return node.textContent || ''
  }
  if (!(node instanceof HTMLElement)) {
    return ''
  }

  const text = childrenToMarkdown(node)
  const tag = node.tagName.toLowerCase()
  if (tag === 'strong' || tag === 'b') {
    return `**${text}**`
  }
  if (tag === 'code') {
    return `\`${node.textContent || ''}\``
  }
  if (tag === 'a') {
    return `[${text}](${node.getAttribute('href') || ''})`
  }
  if (tag === 'img') {
    return `![${node.getAttribute('alt') || ''}](${node.getAttribute('src') || ''})`
  }
  if (tag === 'br') {
    return '\n'
  }
  return text
}

const nodeToMarkdown = (node: Node): string => {
  if (node.nodeType === Node.TEXT_NODE) {
    return (node.textContent || '').trim()
  }
  if (!(node instanceof HTMLElement)) {
    return ''
  }

  const tag = node.tagName.toLowerCase()
  if (tag === 'h1') {
    return `# ${childrenToMarkdown(node)}`
  }
  if (tag === 'h2') {
    return `## ${childrenToMarkdown(node)}`
  }
  if (tag === 'h3') {
    return `### ${childrenToMarkdown(node)}`
  }
  if (tag === 'blockquote') {
    return childrenToMarkdown(node).split('\n').map(line => `> ${line}`).join('\n')
  }
  if (tag === 'pre') {
    return `\`\`\`\n${node.textContent || ''}\n\`\`\``
  }
  if (tag === 'ul') {
    return Array.from(node.children).map(child => `- ${childrenToMarkdown(child)}`).join('\n')
  }
  if (tag === 'ol') {
    return Array.from(node.children).map((child, index) => `${index + 1}. ${childrenToMarkdown(child)}`).join('\n')
  }
  if (tag === 'p' || tag === 'div') {
    return childrenToMarkdown(node)
  }
  return childrenToMarkdown(node)
}

const escapeHtml = (value: string) => value
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;')

const renderInline = (value: string) => {
  let html = escapeHtml(value)
  html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">')
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noreferrer">$1</a>')
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>')
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
  return html
}

const renderMarkdown = (source: string) => {
  const lines = source.split('\n')
  const blocks: string[] = []
  let inCode = false
  let codeBuffer: string[] = []

  for (const line of lines) {
    if (line.startsWith('```')) {
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
      continue
    }
    if (line.startsWith('# ')) {
      blocks.push(`<h1>${renderInline(line.slice(2))}</h1>`)
    } else if (line.startsWith('## ')) {
      blocks.push(`<h2>${renderInline(line.slice(3))}</h2>`)
    } else if (line.startsWith('### ')) {
      blocks.push(`<h3>${renderInline(line.slice(4))}</h3>`)
    } else if (/^[-*]\s+/.test(line)) {
      blocks.push(`<ul><li>${renderInline(line.replace(/^[-*]\s+/, ''))}</li></ul>`)
    } else {
      blocks.push(`<p>${renderInline(line)}</p>`)
    }
  }
  return blocks.join('')
}
</script>

<template>
  <section class="editor-page">
    <header class="editor-header editor-hero">
      <div>
        <p class="admin-kicker">Markdown Publisher</p>
        <h1>{{ articleId ? '编辑文章' : '新建文章' }}</h1>
        <p class="admin-page-subtitle">
          支持 Markdown 写作、图片上传、封面配置和实时预览。
        </p>
      </div>
      <div class="editor-actions">
        <NuxtLink to="/admin/articles" class="admin-secondary-link">
          返回列表
        </NuxtLink>
        <label class="admin-secondary-button">
          导入 MD
          <input type="file" accept=".md,.markdown" class="hidden" @change="onMarkdownSelected">
        </label>
        <label class="admin-secondary-button">
          上传图片
          <input type="file" accept="image/*" multiple class="hidden" @change="onImagesSelected">
        </label>
        <label class="admin-secondary-button">
          上传 MD 文件夹
          <input type="file" multiple webkitdirectory directory class="hidden" @change="onFolderSelected">
        </label>
        <button type="button" class="admin-secondary-button" :disabled="saving" @click="saveArticle('DRAFT')">
          保存草稿
        </button>
        <button type="button" class="admin-primary-button" :disabled="saving" @click="saveArticle('PUBLISHED')">
          发布
        </button>
        <button
          v-if="articleId"
          type="button"
          class="admin-danger-button"
          :disabled="deleting"
          @click="deleteCurrentArticle"
        >
          {{ deleting ? '删除中' : '删除' }}
        </button>
      </div>
    </header>

    <div class="editor-status-strip">
      <div class="editor-cover-preview">
        <img
          :src="coverUrl || '/images/henan-wheatfield-bg.png'"
          alt="文章封面预览"
        >
      </div>
      <div>
        <span :class="['admin-status', status === 'PUBLISHED' ? 'published' : 'draft']">
          {{ status === 'PUBLISHED' ? '已发布' : '草稿' }}
        </span>
        <h2>{{ title || '未命名文章' }}</h2>
        <p>{{ slug || '保存时将根据标题自动生成 slug' }}</p>
      </div>
      <label class="editor-status-select">
        <span>发布状态</span>
        <select v-model="status">
          <option value="DRAFT">草稿</option>
          <option value="PUBLISHED">已发布</option>
        </select>
      </label>
    </div>

    <div class="editor-meta">
      <label>
        <span>标题</span>
        <input v-model="title" placeholder="请输入文章标题">
      </label>
      <label>
        <span>Slug</span>
        <input v-model="slug" placeholder="留空将自动生成">
      </label>
      <label>
        <span>标签</span>
        <input v-model="tagsText" placeholder="用逗号分隔，例如 Nuxt, Spring Boot">
      </label>
      <label>
        <span>分类</span>
        <select v-model="categoryId">
          <option value="">自动判断 / 未分类</option>
          <option
            v-for="category in categories"
            :key="category.id"
            :value="category.id"
          >
            {{ category.name }}
          </option>
        </select>
      </label>
      <label class="editor-toggle-field">
        <span>自动分类</span>
        <input v-model="autoCategory" type="checkbox">
        <em>{{ autoCategory ? '保存时按内容重新分类' : '使用手动选择的分类' }}</em>
      </label>
      <label class="editor-toggle-field">
        <span>文章置顶</span>
        <input v-model="isTop" type="checkbox">
        <em>{{ isTop ? '首页与归档优先展示' : '按发布时间排序' }}</em>
      </label>
      <label>
        <span>封面图</span>
        <input v-model="coverUrl" placeholder="上传图片后会自动填入第一张">
        <div class="editor-cover-actions">
          <label class="admin-secondary-button compact">
            上传封面
            <input type="file" accept="image/*" class="hidden" @change="onCoverSelected">
          </label>
          <button type="button" class="admin-secondary-button compact" @click="useFirstMarkdownImageAsCover">
            正文首图
          </button>
        </div>
      </label>
      <label class="editor-summary">
        <span>摘要</span>
        <textarea v-model="summary" rows="3" placeholder="文章摘要，会显示在首页目录卡片中" />
      </label>
    </div>

    <p v-if="errorMessage" class="login-error">{{ errorMessage }}</p>
    <p v-else-if="uploadMessage" class="editor-message">{{ uploadMessage }}</p>

    <div class="editor-workbench typora-workbench">
      <div class="editor-pane typora-pane">
        <div class="pane-title pane-title-row">
          <span>{{ previewEditMode ? 'Typora 编辑' : 'Markdown 源码' }}</span>
          <span class="editor-inline-stats">
            {{ editorStats.words }} 字 · {{ editorStats.images }} 图 · {{ editorStats.headings }} 标题 · {{ editorStats.minutes }} 分钟
          </span>
        </div>
        <div class="editor-toolbar" aria-label="Markdown 工具栏">
          <button type="button" title="二级标题" @click="applyEditorTool('h2')">H2</button>
          <button type="button" title="三级标题" @click="applyEditorTool('h3')">H3</button>
          <button type="button" title="加粗" @click="applyEditorTool('bold')">B</button>
          <button type="button" title="引用" @click="applyEditorTool('quote')">“”</button>
          <button type="button" title="代码" @click="applyEditorTool('code')">{ }</button>
          <button type="button" title="列表" @click="applyEditorTool('list')">•</button>
          <button type="button" title="分割线" @click="applyEditorTool('divider')">—</button>
          <button type="button" title="图片语法" @click="applyEditorTool('image')">图</button>
          <button
            type="button"
            class="preview-edit-toggle typora-mode-toggle"
            :class="{ active: previewEditMode }"
            @click="toggleEditorMode"
          >
            {{ previewEditMode ? 'Markdown 源码' : '预览编辑' }}
          </button>
        </div>
        <div
          class="markdown-editor-wrap"
          :class="{ dragging: isDraggingImages, uploading: uploadingImages }"
          @dragover="onEditorDragOver"
          @dragleave="onEditorDragLeave"
          @drop.prevent="onEditorDrop"
        >
          <p class="editor-drop-hint">
            {{ uploadingImages ? '图片上传中...' : '松开即可上传图片并插入到光标处' }}
          </p>
        <textarea
          v-if="!previewEditMode"
          ref="editorRef"
          v-model="markdown"
          class="markdown-editor"
          spellcheck="false"
          @paste="onEditorPaste"
        />
        </div>
      </div>
      <div class="editor-pane preview-pane typora-preview-pane">
        <article
          v-if="previewEditMode"
          ref="previewEditableRef"
          class="markdown-preview"
          :class="{ editable: previewEditMode }"
          :contenteditable="previewEditMode"
          v-html="previewHtml"
          @blur="syncPreviewEdits"
        />
      </div>
    </div>
  </section>
</template>

