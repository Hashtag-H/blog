<script setup lang="ts">
import AdminToast from '~/components/admin/AdminToast.vue'
import { useAdminToast } from '~/composables/useAdminToast'

definePageMeta({
  layout: false
})

useHead({ title: '后台登录' })

interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

interface LoginResponse {
  token: string
  username: string
}

const { apiFetch } = useApi()
const { showToast } = useAdminToast()
const router = useRouter()

const username = ref('admin')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

onMounted(() => {
  if (window.localStorage.getItem('admin_token')) {
    router.push('/admin')
  }
})

const login = async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    const response = await apiFetch<ApiResponse<LoginResponse>>('/auth/login', {
      method: 'POST',
      body: {
        username: username.value,
        password: password.value
      }
    })
    window.localStorage.setItem('admin_token', response.data.token)
    showToast({ type: 'success', title: '登录成功', message: '正在进入后台。' })
    await router.push('/admin')
  } catch {
    errorMessage.value = '用户名或密码错误'
    showToast({ type: 'error', title: '登录失败', message: '用户名或密码错误。' })
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="login-page">
    <AdminToast />
    <form class="login-panel" @submit.prevent="login">
      <p class="admin-kicker">Admin Login</p>
      <h1>后台登录</h1>
      <label>
        <span>用户名</span>
        <input v-model="username" autocomplete="username">
      </label>
      <label>
        <span>密码</span>
        <input v-model="password" type="password" autocomplete="current-password">
      </label>
      <p v-if="errorMessage" class="login-error">{{ errorMessage }}</p>
      <button type="submit" class="admin-primary-button" :disabled="loading">
        {{ loading ? '登录中...' : '登录' }}
      </button>
    </form>
  </main>
</template>
