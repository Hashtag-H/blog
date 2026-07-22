<script setup lang="ts">
import { useAdminToast } from '~/composables/useAdminToast'

const { toasts, dismissToast } = useAdminToast()
</script>

<template>
  <ClientOnly>
    <Teleport to="body">
      <div v-if="toasts.length" class="admin-toast-stack" aria-live="polite">
        <article
          v-for="toast in toasts"
          :key="toast.id"
          :class="['admin-toast', `admin-toast-${toast.type}`]"
        >
          <span class="admin-toast-icon">
            {{ toast.type === 'success' ? '✓' : toast.type === 'error' ? '!' : 'i' }}
          </span>
          <div class="admin-toast-content">
            <strong>{{ toast.title }}</strong>
            <p v-if="toast.message">{{ toast.message }}</p>
          </div>
          <button type="button" aria-label="关闭提示" @click="dismissToast(toast.id)">
            ×
          </button>
        </article>
      </div>
    </Teleport>
  </ClientOnly>
</template>
