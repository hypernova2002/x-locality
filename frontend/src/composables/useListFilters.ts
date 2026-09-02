import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

/**
 * Filter state for a paginated list view: reads initial values from the
 * current URL query, keeps them in sync as they change, and hands back
 * only the non-empty ones for building an API request. Extracted from the
 * hand-rolled version of this in TranslationsView.vue once Locales,
 * ContextTags, and GlossaryTerms needed the same thing.
 *
 * `defaults` also defines the filter keys - pass '' for every field.
 */
export function useListFilters<T extends Record<string, string>>(defaults: T) {
  const route = useRoute()
  const router = useRouter()

  const keys = Object.keys(defaults) as (keyof T)[]

  const initial = {} as T
  for (const key of keys) {
    const raw = route.query[key as string]
    initial[key] = (typeof raw === 'string' ? raw : defaults[key]) as T[keyof T]
  }
  const filters = reactive(initial) as T

  const showFilters = ref(keys.some((key) => filters[key]))

  function syncQuery() {
    const query: Record<string, string> = {}
    for (const key of keys) {
      if (filters[key]) query[key as string] = filters[key]
    }
    router.replace({ query })
  }

  function toParams(): Partial<Record<keyof T, string>> {
    const params: Partial<Record<keyof T, string>> = {}
    for (const key of keys) {
      if (filters[key]) params[key] = filters[key]
    }
    return params
  }

  function clear() {
    for (const key of keys) {
      filters[key] = defaults[key]
    }
  }

  return { filters, showFilters, syncQuery, toParams, clear }
}
