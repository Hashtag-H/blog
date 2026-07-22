<script setup lang="ts">
import { useAdminToast } from '~/composables/useAdminToast'

definePageMeta({
  layout: 'admin'
})

useHead({ title: '账号与站点设置' })

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

interface SiteSettings {
  siteTitle: string
  displayName: string
  motto: string
  avatarUrl: string
  backgroundUrl: string
  announcement: string
  githubUrl: string
  rssUrl: string
  live2dEnabled: boolean
  live2dCdnPath: string
  live2dModelId: number
  live2dTextureId: number
}

interface AccountProfile {
  username: string
  displayName: string
  email?: string
}

const { apiFetch } = useApi()
const { showToast } = useAdminToast()

const site = reactive<SiteSettings>({
  siteTitle: '',
  displayName: '',
  motto: '',
  avatarUrl: '',
  backgroundUrl: '',
  announcement: '',
  githubUrl: '',
  rssUrl: '',
  live2dEnabled: true,
  live2dCdnPath: '',
  live2dModelId: 0,
  live2dTextureId: 0
})
const account = reactive<AccountProfile>({
  username: '',
  displayName: '',
  email: ''
})
const passwordForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const loading = ref(false)
const savingSite = ref(false)
const savingAccount = ref(false)
const savingPassword = ref(false)
const uploading = ref('')
const errorMessage = ref('')
const successMessage = ref('')

const assignSite = (next: SiteSettings) => {
  Object.assign(site, next)
}

const assignAccount = (next: AccountProfile) => {
  Object.assign(account, next)
}

const loadSettings = async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    const [siteResponse, accountResponse] = await Promise.all([
      apiFetch<ApiResponse<SiteSettings>>('/admin/settings/site'),
      apiFetch<ApiResponse<AccountProfile>>('/admin/settings/account')
    ])
    assignSite(siteResponse.data)
    assignAccount(accountResponse.data)
  } catch {
    errorMessage.value = '设置加载失败，请确认已经登录'
    showToast({ type: 'error', title: '设置加载失败', message: '请确认后台登录状态后重试。' })
  } finally {
    loading.value = false
  }
}

const saveSite = async () => {
  savingSite.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const response = await apiFetch<ApiResponse<SiteSettings>>('/admin/settings/site', {
      method: 'PUT',
      body: site
    })
    assignSite(response.data)
    successMessage.value = '前台展示设置已保存'
    showToast({ type: 'success', title: '前台设置保存成功', message: '首页头像、背景和公告会使用最新配置。' })
  } catch {
    errorMessage.value = '前台展示设置保存失败'
    showToast({ type: 'error', title: '前台设置保存失败', message: '请稍后再试。' })
  } finally {
    savingSite.value = false
  }
}

const saveAccount = async () => {
  savingAccount.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const response = await apiFetch<ApiResponse<AccountProfile>>('/admin/settings/account', {
      method: 'PUT',
      body: account
    })
    assignAccount(response.data)
    successMessage.value = '后台账号资料已保存'
    showToast({ type: 'success', title: '账号资料保存成功', message: '后台账号信息已更新。' })
  } catch {
    errorMessage.value = '账号资料保存失败，用户名可能已存在'
    showToast({ type: 'error', title: '账号资料保存失败', message: '用户名可能已存在。' })
  } finally {
    savingAccount.value = false
  }
}

const savePassword = async () => {
  if (passwordForm.newPassword !== passwordForm.confirmPassword) {
    errorMessage.value = '两次输入的新密码不一致'
    showToast({ type: 'error', title: '密码确认失败', message: '两次输入的新密码不一致。' })
    return
  }

  savingPassword.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await apiFetch<ApiResponse<void>>('/admin/settings/account/password', {
      method: 'PUT',
      body: {
        username: account.username,
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword
      }
    })
    passwordForm.currentPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
    successMessage.value = '后台密码已更新，下次登录请使用新密码'
    showToast({ type: 'success', title: '密码更新成功', message: '下次登录请使用新密码。' })
  } catch {
    errorMessage.value = '密码更新失败，请检查当前密码'
    showToast({ type: 'error', title: '密码更新失败', message: '请检查当前密码是否正确。' })
  } finally {
    savingPassword.value = false
  }
}

const uploadImage = async (event: Event, target: 'avatarUrl' | 'backgroundUrl') => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) {
    return
  }

  uploading.value = target
  errorMessage.value = ''
  successMessage.value = ''
  try {
    const formData = new FormData()
    formData.append('file', file)
    const response = await apiFetch<ApiResponse<UploadedAsset>>('/admin/uploads/images', {
      method: 'POST',
      body: formData
    })
    site[target] = response.data.url
    successMessage.value = target === 'avatarUrl' ? '头像已上传，请保存设置' : '背景图已上传，请保存设置'
    showToast({
      type: 'success',
      title: target === 'avatarUrl' ? '头像上传成功' : '背景图上传成功',
      message: '记得点击保存前台设置。'
    })
  } catch {
    errorMessage.value = '图片上传失败'
    showToast({ type: 'error', title: '图片上传失败', message: '请检查图片格式或登录状态。' })
  } finally {
    uploading.value = ''
    input.value = ''
  }
}

onMounted(loadSettings)
</script>

<template>
  <section class="admin-page">
    <header class="admin-page-header">
      <div>
        <p class="admin-kicker">Settings</p>
        <h1>账号与站点设置</h1>
        <p class="admin-page-subtitle">
          调整前台头像、背景图、公告信息，也可以修改后台账号资料和密码。
        </p>
      </div>
      <button type="button" class="admin-secondary-button" :disabled="loading" @click="loadSettings">
        刷新
      </button>
    </header>

    <p v-if="errorMessage" class="login-error">{{ errorMessage }}</p>
    <p v-else-if="successMessage" class="editor-message">{{ successMessage }}</p>

    <div class="settings-grid">
      <form class="admin-form-panel" @submit.prevent="saveSite">
        <h2>前台展示</h2>
        <div class="settings-preview">
          <img :src="site.avatarUrl || '/images/profile-id.webp'" alt="前台头像">
          <span :style="{ backgroundImage: `url(${site.backgroundUrl || '/images/henan-wheatfield-bg.png'})` }" />
        </div>
        <label>
          <span>站点标题</span>
          <input v-model="site.siteTitle" placeholder="河南娃的小窝">
        </label>
        <label>
          <span>前台昵称</span>
          <input v-model="site.displayName" placeholder="河南娃">
        </label>
        <label>
          <span>签名</span>
          <input v-model="site.motto" placeholder="愿麦浪祝颂你的旅途">
        </label>
        <label>
          <span>头像地址</span>
          <input v-model="site.avatarUrl" placeholder="/images/profile-id.webp">
        </label>
        <label class="admin-inline-upload">
          <span>上传头像</span>
          <input type="file" accept="image/*" @change="uploadImage($event, 'avatarUrl')">
        </label>
        <label>
          <span>背景图地址</span>
          <input v-model="site.backgroundUrl" placeholder="/images/henan-wheatfield-bg.png">
        </label>
        <label class="admin-inline-upload">
          <span>上传背景</span>
          <input type="file" accept="image/*" @change="uploadImage($event, 'backgroundUrl')">
        </label>
        <label>
          <span>公告</span>
          <textarea v-model="site.announcement" rows="5" placeholder="显示在前台侧边栏公告卡片中" />
        </label>
        <label>
          <span>GitHub</span>
          <input v-model="site.githubUrl" placeholder="https://github.com/">
        </label>
        <label>
          <span>RSS</span>
          <input v-model="site.rssUrl" placeholder="/rss.xml">
        </label>
        <label class="admin-switch-row">
          <input v-model="site.live2dEnabled" type="checkbox">
          <span>启用右下角 Live2D 形象</span>
        </label>
        <label>
          <span>Live2D 模型源</span>
          <input v-model="site.live2dCdnPath" placeholder="https://fastly.jsdelivr.net/gh/fghrsh/live2d_api@1.0.1/">
        </label>
        <div class="admin-split-fields">
          <label>
            <span>默认模型编号</span>
            <input v-model.number="site.live2dModelId" type="number" min="0">
          </label>
          <label>
            <span>默认贴图编号</span>
            <input v-model.number="site.live2dTextureId" type="number" min="0">
          </label>
        </div>
        <button type="submit" class="admin-primary-button" :disabled="savingSite || !!uploading">
          {{ savingSite ? '保存中' : '保存前台设置' }}
        </button>
      </form>

      <div class="settings-stack">
        <form class="admin-form-panel" @submit.prevent="saveAccount">
          <h2>后台账号</h2>
          <label>
            <span>用户名</span>
            <input v-model="account.username" required>
          </label>
          <label>
            <span>显示名</span>
            <input v-model="account.displayName" required>
          </label>
          <label>
            <span>邮箱</span>
            <input v-model="account.email" type="email">
          </label>
          <button type="submit" class="admin-primary-button" :disabled="savingAccount">
            {{ savingAccount ? '保存中' : '保存账号资料' }}
          </button>
        </form>

        <form class="admin-form-panel" @submit.prevent="savePassword">
          <h2>修改密码</h2>
          <label>
            <span>当前密码</span>
            <input v-model="passwordForm.currentPassword" type="password" autocomplete="current-password" required>
          </label>
          <label>
            <span>新密码</span>
            <input v-model="passwordForm.newPassword" type="password" autocomplete="new-password" required>
          </label>
          <label>
            <span>确认新密码</span>
            <input v-model="passwordForm.confirmPassword" type="password" autocomplete="new-password" required>
          </label>
          <button type="submit" class="admin-primary-button" :disabled="savingPassword">
            {{ savingPassword ? '更新中' : '更新密码' }}
          </button>
        </form>
      </div>
    </div>
  </section>
</template>
