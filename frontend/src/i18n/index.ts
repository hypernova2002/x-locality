import { createI18n } from 'vue-i18n'
import en from './locales/en.json'

// Message catalogs are static, compiled-in files - never call the LLM (or
// any translation API) to translate the UI itself. Add more locale files
// under ./locales and register them here when needed.
export const i18n = createI18n({
  legacy: false,
  locale: 'en',
  fallbackLocale: 'en',
  messages: { en },
})
