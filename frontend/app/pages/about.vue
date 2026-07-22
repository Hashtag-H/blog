<script setup lang="ts">
import { useSiteSettings } from '~/composables/useSiteSettings'

useHead({ title: '关于' })

const { settings, loadSiteSettings } = useSiteSettings()

onMounted(loadSiteSettings)
</script>

<template>
  <section class="public-page">
    <header class="public-hero compact about-hero">
      <img :src="settings.avatarUrl || '/images/profile-id.webp'" :alt="settings.displayName">
      <p class="public-kicker">About</p>
      <h1>{{ settings.displayName }}</h1>
      <p>{{ settings.motto }}</p>
    </header>

    <div class="about-layout">
      <article class="about-card wide">
        <h2>关于这个小站</h2>
        <p>
          这里会放编程实践、深度学习笔记、读书札记和一些生活里的短句。文章不追求把所有东西讲完，更希望把某个问题真正讲清楚一点。
        </p>
        <p>
          目前站点正在逐步变成一个个人知识博客：能写 Markdown、管理分类标签、上传图片，也能把日常学习整理成更容易回看的路径。
        </p>
      </article>

      <article class="about-card">
        <h2>常写主题</h2>
        <div class="about-chip-list">
          <span>深度学习</span>
          <span>编程</span>
          <span>读书札记</span>
          <span>名言赏析</span>
          <span>生活随笔</span>
        </div>
      </article>

      <article class="about-card">
        <h2>站点状态</h2>
        <ul class="about-list">
          <li>前台：Butterfly 风格阅读体验</li>
          <li>后台：文章、分类、账号与站点设置</li>
          <li>写作：Markdown、图片上传、预览编辑</li>
        </ul>
      </article>
    </div>
  </section>
</template>
