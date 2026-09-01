<script setup lang="ts">
import { ref, computed, onMounted, provide, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Select from 'openvue/select'
import Button from 'openvue/button'
import Avatar from 'openvue/avatar'
import Menu from 'openvue/menu'
import AutoComplete from 'openvue/autocomplete'
import ProgressSpinner from 'openvue/progressspinner'
import { useAuthStore } from '@/stores/auth'
import { useAccountStore } from '@/stores/account'
import { useThemeStore } from '@/stores/theme'
import * as projectsApi from '@/api/projects'
import * as translationsApi from '@/api/translations'
import type { Project, TranslationGroup } from '@/api/types'
import {
  PROJECT_KEY,
  PROJECTS_KEY,
  PROJECTS_LOADING_KEY,
  RELOAD_PROJECTS_KEY,
} from '@/composables/useProject'
import { rememberLastProject } from '@/lib/lastProject'

const auth = useAuthStore()
const accountStore = useAccountStore()
const theme = useThemeStore()
const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const projects = ref<Project[]>([])
const projectsLoading = ref(true)

async function loadProjects() {
  projectsLoading.value = true
  const { data } = await projectsApi.listProjects(auth.token!)
  projects.value = data
  projectsLoading.value = false
}

onMounted(loadProjects)
onMounted(() => accountStore.load(auth.token!))

const projectId = computed(() => route.params.projectId as string | undefined)
const currentProject = computed(
  () => projects.value.find((p) => p.id === projectId.value) ?? null,
)

watch(currentProject, (project) => {
  if (project) rememberLastProject(project.id)
})

provide(PROJECT_KEY, currentProject)
provide(PROJECTS_KEY, projects)
provide(PROJECTS_LOADING_KEY, projectsLoading)
provide(RELOAD_PROJECTS_KEY, loadProjects)

const projectOptions = computed(() => projects.value.map((p) => ({ label: p.name, value: p.id })))

// The sidebar's project switcher/nav track the last project the route
// actually visited, not the current route directly - otherwise navigating
// to an account-wide page (no :projectId) would blank out the switcher and
// hide the whole per-project nav section.
const selectedProjectId = ref<string | undefined>(undefined)
watch(
  projectId,
  (id) => {
    if (id) selectedProjectId.value = id
  },
  { immediate: true },
)
const selectedProject = computed(
  () => projects.value.find((p) => p.id === selectedProjectId.value) ?? null,
)

function handleProjectSwitch(id: string) {
  router.push({ name: 'project-translations', params: { projectId: id } })
}

const navItems = computed(() => {
  const items = [
    { name: 'project-translations', label: t('nav.translations'), icon: 'oi oi-language' },
    { name: 'project-locales', label: t('nav.locales'), icon: 'oi oi-globe' },
    { name: 'project-context-tags', label: t('nav.contextTags'), icon: 'oi oi-tags' },
    { name: 'project-glossary', label: t('nav.glossary'), icon: 'oi oi-book' },
    { name: 'project-usage', label: t('nav.usage'), icon: 'oi oi-chart-line' },
  ]
  // Every project settings action (including Members, folded into it)
  // requires project-admin access - hiding the whole section for a plain
  // member avoids nav links that always 403.
  if (selectedProject.value?.my_role === 'admin') {
    items.push({ name: 'project-settings', label: t('nav.settings'), icon: 'oi oi-cog' })
  }
  return items
})

function isActive(name: string) {
  if (name === 'project-translations') {
    return route.name === 'project-translations' || route.name === 'project-translation-detail'
  }
  return route.name === name
}

function handleLogout() {
  auth.logout()
  router.push({ name: 'login' })
}

function initials(email: string | undefined) {
  return email ? email[0]!.toUpperCase() : '?'
}

// --- header: page title / breadcrumb ---
const routeTitleKeys: Record<string, string> = {
  projects: 'projects.title',
  'account-usage': 'nav.usage',
  account: 'nav.accountSettings',
  'project-settings': 'nav.settings',
  'project-locales': 'nav.locales',
  'project-context-tags': 'nav.contextTags',
  'project-glossary': 'nav.glossary',
  'project-translations': 'nav.translations',
  'project-usage': 'nav.usage',
}

const breadcrumb = computed(() => {
  if (route.name !== 'project-translation-detail') return null
  return {
    parentLabel: t('nav.translations'),
    parentTo: { name: 'project-translations', params: { projectId: route.params.projectId } },
    current: route.params.key as string,
  }
})

const pageTitle = computed(() => {
  const key = routeTitleKeys[route.name as string]
  return key ? t(key) : ''
})

// --- account menu (top-right) ---
const accountMenu = ref<InstanceType<typeof Menu> | null>(null)
const accountMenuItems = computed(() => [
  { label: t('nav.usage'), icon: 'oi oi-chart-line', command: () => router.push({ name: 'account-usage' }) },
  { label: t('nav.accountSettings'), icon: 'oi oi-user', command: () => router.push({ name: 'account' }) },
  { separator: true },
  {
    label: theme.isDark ? t('nav.lightMode') : t('nav.darkMode'),
    icon: theme.isDark ? 'oi oi-sun' : 'oi oi-moon',
    command: () => theme.toggle(),
  },
  { separator: true },
  { label: t('nav.logOut'), icon: 'oi oi-sign-out', command: handleLogout },
])

function toggleAccountMenu(event: Event) {
  accountMenu.value?.toggle(event)
}

// --- global translation search ---
const searchQuery = ref('')
const searchResults = ref<TranslationGroup[]>([])
// Pinned to whichever project the currently-shown results came from, so a
// project switch (or the sidebar's own project change) between typing and
// clicking a result can't send the navigation to the wrong project - the
// key from a stale search only ever resolves against the project it was
// actually searched in.
let searchResultsProjectId: string | null = null
let searchDebounce: ReturnType<typeof setTimeout> | undefined

function handleSearchComplete(event: { query: string }) {
  const project = selectedProject.value
  if (!project) return

  if (searchDebounce) clearTimeout(searchDebounce)
  searchDebounce = setTimeout(async () => {
    const page = await translationsApi.listTranslationGroups(auth.token!, project.id, {
      search: event.query || undefined,
      limit: 8,
    })
    searchResults.value = page.groups
    searchResultsProjectId = project.id
  }, 300)
}

function handleSearchSelect(event: { value: TranslationGroup }) {
  const targetProjectId = searchResultsProjectId ?? selectedProject.value?.id
  if (!targetProjectId) return

  router.push({
    name: 'project-translation-detail',
    params: { projectId: targetProjectId, key: event.value.key },
  })
  searchQuery.value = ''
  searchResults.value = []
  searchResultsProjectId = null
}

watch(selectedProject, () => {
  searchQuery.value = ''
  searchResults.value = []
  searchResultsProjectId = null
})
</script>

<template>
  <div class="flex h-full bg-[var(--app-canvas)]">
    <aside
      class="flex w-64 shrink-0 flex-col border-r border-[var(--p-content-border-color)] bg-[var(--p-content-background)]"
    >
      <div class="px-4 py-4">
        <RouterLink
          to="/projects"
          class="flex items-center gap-2 text-lg font-semibold tracking-tight text-[var(--p-text-color)]"
        >
          <img
            :src="accountStore.account?.logo_url || '/xlocality-logo.svg'"
            alt=""
            class="h-6 w-6 shrink-0 rounded object-contain"
          />
          <span class="truncate">{{ accountStore.account?.name || t('nav.brand') }}</span>
        </RouterLink>
      </div>

      <div class="border-t border-[var(--p-content-border-color)] px-4 py-4">
        <div class="mb-1.5 flex items-center justify-between">
          <span class="text-xs font-medium text-[var(--p-text-muted-color)]">{{ t('nav.project') }}</span>
          <RouterLink to="/projects" class="text-xs text-[var(--p-primary-color)] hover:underline">
            {{ t('nav.newProject') }}
          </RouterLink>
        </div>
        <Select
          v-if="projects.length > 0"
          :model-value="selectedProjectId"
          :options="projectOptions"
          option-label="label"
          option-value="value"
          filter
          :placeholder="t('nav.selectProject')"
          fluid
          @update:model-value="handleProjectSwitch"
        />
        <RouterLink
          v-else-if="!projectsLoading"
          to="/projects"
          class="block text-sm text-[var(--p-primary-color)] hover:underline"
        >
          {{ t('nav.createFirstProject') }}
        </RouterLink>
      </div>

      <nav v-if="selectedProject" class="flex flex-col gap-0.5 px-3 py-4">
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          :to="{ name: item.name, params: { projectId: selectedProject.id } }"
          class="flex items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium transition-colors"
          :class="
            isActive(item.name)
              ? 'bg-[var(--p-highlight-background)] text-[var(--p-primary-color)]'
              : 'text-[var(--p-text-muted-color)] hover:bg-[var(--p-content-hover-background)]'
          "
        >
          <i :class="item.icon" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="flex-1" />
    </aside>

    <main class="flex min-w-0 flex-1 flex-col">
      <header
        class="flex shrink-0 items-center gap-4 border-b border-[var(--p-content-border-color)] bg-[var(--p-content-background)] px-6 py-3"
      >
        <div class="min-w-0 flex-1">
          <nav v-if="breadcrumb" class="flex items-center gap-1.5 text-sm">
            <RouterLink :to="breadcrumb.parentTo" class="text-[var(--p-text-muted-color)] hover:underline">
              {{ breadcrumb.parentLabel }}
            </RouterLink>
            <i class="oi oi-chevron-right text-xs text-[var(--p-text-muted-color)]" />
            <code class="truncate font-medium text-[var(--p-text-color)]">{{ breadcrumb.current }}</code>
          </nav>
          <h1 v-else-if="pageTitle" class="truncate text-lg font-semibold text-[var(--p-text-color)]">
            {{ pageTitle }}
          </h1>
        </div>

        <AutoComplete
          v-if="selectedProject"
          v-model="searchQuery"
          :suggestions="searchResults"
          option-label="key"
          :placeholder="t('search.placeholder')"
          class="w-full max-w-md"
          fluid
          @complete="handleSearchComplete"
          @option-select="handleSearchSelect"
        >
          <template #option="{ option }">
            <div class="flex min-w-0 flex-col gap-0.5 py-0.5">
              <code class="text-xs text-[var(--p-text-muted-color)]">{{ option.key }}</code>
              <span class="truncate text-sm text-[var(--p-text-color)]">{{ option.source_text }}</span>
            </div>
          </template>
        </AutoComplete>

        <Button text severity="secondary" class="shrink-0" @click="toggleAccountMenu">
          <Avatar :label="initials(auth.user?.email)" shape="circle" size="normal" class="mr-2" />
          <span class="max-w-[10rem] truncate text-sm text-[var(--p-text-color)]">{{ auth.user?.email }}</span>
          <i class="oi oi-chevron-down ml-2 text-xs text-[var(--p-text-muted-color)]" />
        </Button>
        <Menu ref="accountMenu" :model="accountMenuItems" :popup="true" class="min-w-[12rem]" />
      </header>

      <div class="flex-1 overflow-y-auto p-6">
        <div class="mx-auto max-w-5xl">
          <div v-if="projectId && !currentProject" class="flex justify-center py-12">
            <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
          </div>
          <RouterView v-else />
        </div>
      </div>
    </main>
  </div>
</template>
