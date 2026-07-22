<script setup lang="ts">
import AdminToast from '~/components/admin/AdminToast.vue'

const router = useRouter()

const logout = async () => {
  window.localStorage.removeItem('admin_token')
  await router.push('/admin/login')
}

onMounted(async () => {
  if (!window.localStorage.getItem('admin_token')) {
    await router.push('/admin/login')
  }
})
</script>

<template>
  <div class="admin-shell">
    <aside class="admin-sidebar">
      <NuxtLink to="/admin" class="admin-brand">AI Knowledge Admin</NuxtLink>
      <nav class="admin-nav">
        <NuxtLink to="/admin">控制台</NuxtLink>
        <NuxtLink to="/admin/articles">文章管理</NuxtLink>
        <NuxtLink to="/admin/articles/new">新建文章</NuxtLink>
        <NuxtLink to="/admin/categories">分类管理</NuxtLink>
        <NuxtLink to="/admin/settings">账号设置</NuxtLink>
      </nav>
      <button type="button" class="admin-logout" @click="logout">退出登录</button>
    </aside>
    <main class="admin-main">
      <slot />
    </main>
    <AdminToast />
  </div>
</template>
