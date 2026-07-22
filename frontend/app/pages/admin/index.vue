<script setup lang="ts">
definePageMeta({
  layout: 'admin'
})

useHead({ title: '后台控制台' })
</script>

<template>
  <section class="admin-dashboard">
    <div>
      <p class="admin-kicker">Dashboard</p>
      <h1>控制台</h1>
      <p>这里用于管理文章发布、Markdown 导入和图片素材上传。</p>
    </div>
    <NuxtLink to="/admin/articles/new" class="admin-primary-link">写新文章</NuxtLink>
  </section>
</template>
