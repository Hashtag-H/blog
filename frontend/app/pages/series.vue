<script setup lang="ts">
useHead({ title: '游戏' })

const gameNotes = [
  {
    title: '灵感收藏',
    text: '记录喜欢的画面、交互和叙事节奏，给以后做小游戏或页面动效留参考。',
    progress: '整理中'
  },
  {
    title: '小游戏实验',
    text: '适合放一些 Canvas、Three.js 或轻量交互 demo，让博客偶尔有一点可玩的东西。',
    progress: '待建设'
  },
  {
    title: '作品清单',
    text: '把玩过、想玩、值得复盘的作品按类型归档，不只写评价，也写设计观察。',
    progress: '计划中'
  }
]
</script>

<template>
  <section class="public-page">
    <header class="public-hero compact">
      <p class="public-kicker">Games</p>
      <h1>游戏</h1>
      <p>这里会放游戏相关的灵感、交互实验和作品观察。先把入口做漂亮，内容慢慢长出来。</p>
    </header>

    <div class="game-grid">
      <article
        v-for="note in gameNotes"
        :key="note.title"
        class="game-card"
      >
        <span>{{ note.progress }}</span>
        <h2>{{ note.title }}</h2>
        <p>{{ note.text }}</p>
      </article>
    </div>

    <div class="game-roadmap">
      <h2>后续可以怎么扩展</h2>
      <ol>
        <li>把小游戏 demo 独立成可玩的页面。</li>
        <li>给每个游戏笔记加标签和封面。</li>
        <li>和文章分类联动，形成“游戏设计”专题。</li>
      </ol>
    </div>
  </section>
</template>
