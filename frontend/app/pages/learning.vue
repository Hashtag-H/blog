<script setup lang="ts">
useHead({ title: '生活' })

const moments = [
  {
    title: '写一点生活',
    date: '日常',
    text: '把校园、散步、阅读和偶尔冒出来的想法收起来，给技术文章之间留一点呼吸。'
  },
  {
    title: '学习节奏',
    date: '计划',
    text: '长期主题会围绕深度学习、推荐系统、工程实践展开，每篇文章尽量留下可复用的笔记。'
  },
  {
    title: '灵感摘录',
    date: '碎片',
    text: '名言赏析、句子摘录和短评会放在这里，像给自己留的一盏小灯。'
  }
]
</script>

<template>
  <section class="public-page">
    <header class="public-hero compact">
      <p class="public-kicker">Life</p>
      <h1>生活</h1>
      <p>技术之外，也记录那些柔软、松弛、但值得回头看的时刻。</p>
    </header>

    <div class="life-board">
      <article
        v-for="item in moments"
        :key="item.title"
        class="life-card"
      >
        <span>{{ item.date }}</span>
        <h2>{{ item.title }}</h2>
        <p>{{ item.text }}</p>
      </article>
    </div>

    <div class="quote-band">
      <p>“慢一点也没关系，重要的是知道自己正在往哪里走。”</p>
      <span>留给未来文章的一句旁白</span>
    </div>
  </section>
</template>
