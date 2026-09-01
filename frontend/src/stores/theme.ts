import { defineStore } from 'pinia'
import { ref } from 'vue'

const STORAGE_KEY = 'x-locality:theme'

export const useThemeStore = defineStore('theme', () => {
  // index.html already applied the class before Vue mounted (avoids a
  // flash of the wrong theme) - just read that state back rather than
  // re-deciding it.
  const isDark = ref(document.documentElement.classList.contains('p-dark'))

  function toggle() {
    isDark.value = !isDark.value
    document.documentElement.classList.toggle('p-dark', isDark.value)
    localStorage.setItem(STORAGE_KEY, isDark.value ? 'dark' : 'light')
  }

  return { isDark, toggle }
})
