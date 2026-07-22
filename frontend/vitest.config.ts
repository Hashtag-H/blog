import { defineConfig } from 'vitest/config'

export default defineConfig({
  cacheDir: '.vite-cache',
  test: {
    globals: false
  }
})

