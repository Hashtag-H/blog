<script setup lang="ts">
import { useAdminToast } from '~/composables/useAdminToast'

definePageMeta({
  layout: 'admin'
})

useHead({ title: '分类管理' })

interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

interface Category {
  id: number
  name: string
  slug: string
  description?: string
  sort: number
  articleCount: number
  createdAt: string
  updatedAt: string
}

const { apiFetch } = useApi()
const { showToast } = useAdminToast()

const categories = ref<Category[]>([])
const editingId = ref<number | null>(null)
const name = ref('')
const slug = ref('')
const description = ref('')
const sort = ref(0)
const loading = ref(false)
const saving = ref(false)
const deletingId = ref<number | null>(null)
const errorMessage = ref('')
const successMessage = ref('')

const resetForm = () => {
  editingId.value = null
  name.value = ''
  slug.value = ''
  description.value = ''
  sort.value = 0
}

const loadCategories = async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    const response = await apiFetch<ApiResponse<Category[]>>('/admin/categories')
    categories.value = response.data
  } catch {
    errorMessage.value = '分类加载失败，请确认已经登录'
    showToast({ type: 'error', title: '分类加载失败', message: '请确认后台登录状态后重试。' })
  } finally {
    loading.value = false
  }
}

const editCategory = (category: Category) => {
  editingId.value = category.id
  name.value = category.name
  slug.value = category.slug
  description.value = category.description || ''
  sort.value = category.sort || 0
}

const saveCategory = async () => {
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const payload = {
      name: name.value,
      slug: slug.value,
      description: description.value,
      sort: sort.value
    }
    const url = editingId.value ? `/admin/categories/${editingId.value}` : '/admin/categories'
    const method = editingId.value ? 'PUT' : 'POST'
    await apiFetch<ApiResponse<Category>>(url, { method, body: payload })
    successMessage.value = editingId.value ? '分类已更新' : '分类已创建'
    showToast({
      type: 'success',
      title: editingId.value ? '分类更新成功' : '分类创建成功',
      message: name.value || '分类信息已保存。'
    })
    resetForm()
    await loadCategories()
  } catch {
    errorMessage.value = '保存失败，请检查名称或 slug 是否重复'
    showToast({ type: 'error', title: '分类保存失败', message: '请检查名称或 slug 是否重复。' })
  } finally {
    saving.value = false
  }
}

const deleteCategory = async (category: Category) => {
  const confirmed = window.confirm(`确认删除分类「${category.name}」吗？该分类下文章会变为未分类。`)
  if (!confirmed) {
    return
  }

  deletingId.value = category.id
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await apiFetch<ApiResponse<void>>(`/admin/categories/${category.id}`, { method: 'DELETE' })
    successMessage.value = '分类已删除'
    showToast({ type: 'success', title: '分类删除成功', message: `「${category.name}」已删除。` })
    await loadCategories()
    if (editingId.value === category.id) {
      resetForm()
    }
  } catch {
    errorMessage.value = '删除失败，请稍后再试'
    showToast({ type: 'error', title: '分类删除失败', message: '请稍后再试。' })
  } finally {
    deletingId.value = null
  }
}

onMounted(loadCategories)
</script>

<template>
  <section class="admin-page">
    <header class="admin-page-header">
      <div>
        <p class="admin-kicker">Categories</p>
        <h1>分类管理</h1>
        <p class="admin-page-subtitle">
          为博客文章维护编程、深度学习、生活、名言赏析等分类，文章编辑页可自动或手动归类。
        </p>
      </div>
      <button type="button" class="admin-secondary-button" :disabled="loading" @click="loadCategories">
        刷新
      </button>
    </header>

    <p v-if="errorMessage" class="login-error">{{ errorMessage }}</p>
    <p v-else-if="successMessage" class="editor-message">{{ successMessage }}</p>

    <div class="admin-two-column">
      <form class="admin-form-panel" @submit.prevent="saveCategory">
        <h2>{{ editingId ? '编辑分类' : '新增分类' }}</h2>
        <label>
          <span>名称</span>
          <input v-model="name" required placeholder="例如 深度学习">
        </label>
        <label>
          <span>Slug</span>
          <input v-model="slug" placeholder="留空根据名称生成">
        </label>
        <label>
          <span>排序</span>
          <input v-model.number="sort" type="number">
        </label>
        <label>
          <span>描述</span>
          <textarea v-model="description" rows="4" placeholder="这个分类收录什么内容" />
        </label>
        <div class="admin-form-actions">
          <button type="submit" class="admin-primary-button" :disabled="saving">
            {{ saving ? '保存中' : '保存分类' }}
          </button>
          <button v-if="editingId" type="button" class="admin-secondary-button" @click="resetForm">
            取消编辑
          </button>
        </div>
      </form>

      <div class="admin-list-panel">
        <article
          v-for="category in categories"
          :key="category.id"
          class="category-admin-row"
        >
          <div>
            <div class="category-admin-title">
              <strong>{{ category.name }}</strong>
              <span>{{ category.articleCount }} 篇文章</span>
            </div>
            <p>{{ category.slug }}</p>
            <small>{{ category.description || '暂无描述' }}</small>
          </div>
          <div class="category-admin-actions">
            <button type="button" class="admin-secondary-button" @click="editCategory(category)">
              编辑
            </button>
            <button
              type="button"
              class="admin-danger-button"
              :disabled="deletingId === category.id"
              @click="deleteCategory(category)"
            >
              {{ deletingId === category.id ? '删除中' : '删除' }}
            </button>
          </div>
        </article>

        <div v-if="!loading && !categories.length" class="admin-empty-state">
          <h2>还没有分类</h2>
          <p>先新增“编程”或“深度学习”这样的分类。</p>
        </div>
      </div>
    </div>
  </section>
</template>
