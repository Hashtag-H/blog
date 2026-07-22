<script setup lang="ts">
import type { ArticleSummary } from '~/types/article'

defineProps<{
  article: ArticleSummary
}>()
</script>

<template>
  <article class="border-b border-white/50 py-6 last:border-b-0 dark:border-slate-700/50">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-sm text-[rgb(var(--text-secondary))]">
      <span>{{ article.category }}</span>
      <span>/</span>
      <time :datetime="article.publishedAt">{{ article.publishedAt }}</time>
      <span>/</span>
      <span>{{ article.readingMinutes }} min read</span>
    </div>
    <NuxtLink :to="`/articles/${article.slug}`" class="block">
      <h2 class="text-xl font-semibold leading-snug transition-colors duration-200 hover:text-primary">
        {{ article.title }}
      </h2>
      <p class="mt-3 max-w-3xl text-[rgb(var(--text-secondary))]">
        {{ article.summary }}
      </p>
    </NuxtLink>
    <div class="mt-4 flex flex-wrap gap-2">
      <span
        v-for="tag in article.tags"
        :key="tag"
        class="rounded-sm bg-white/60 px-2 py-1 text-xs text-[rgb(var(--text-secondary))] dark:bg-slate-800/60"
      >
        {{ tag }}
      </span>
    </div>
  </article>
</template>
