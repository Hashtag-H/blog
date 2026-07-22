import { defineStore } from 'pinia'

export const useThemeStore = defineStore('theme', {
  state: () => ({
    preferred: 'light' as 'light' | 'dark'
  }),
  actions: {
    setTheme(theme: 'light' | 'dark') {
      this.preferred = theme
    }
  }
})

