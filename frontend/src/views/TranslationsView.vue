<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import InputText from 'openvue/inputtext'
import Select from 'openvue/select'
import Checkbox from 'openvue/checkbox'
import Button from 'openvue/button'
import Tag from 'openvue/tag'
import Dialog from 'openvue/dialog'
import Message from 'openvue/message'
import Menu from 'openvue/menu'
import Paginator from 'openvue/paginator'
import ProgressSpinner from 'openvue/progressspinner'
import EmptyState from '@/components/EmptyState.vue'
import { useToast } from 'openvue/usetoast'
import { useConfirm } from 'openvue/useconfirm'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import * as translationsApi from '@/api/translations'
import * as localesApi from '@/api/locales'
import * as usageApi from '@/api/usage'
import { ApiError } from '@/api/client'
import { arrayBufferToBase64 } from '@/lib/base64'
import type { TranslationGroup, TranslationSummary, TranslationUsageData } from '@/api/types'
import type { ImportSummary } from '@/api/translations'

// Above this many locales, a group's row shows a count instead of one tag
// per locale - otherwise a heavily-translated key would blow out the row.
const LANGUAGE_TAG_THRESHOLD = 4

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()
const { project } = useProject()

const PAGE_SIZE = 20

const groups = ref<TranslationGroup[]>([])
const loading = ref(true)
const first = ref(0)
const total = ref(0)

const q = route.query
const showFilters = ref(false)
const keyFilter = ref(typeof q.key === 'string' ? q.key : '')
const statusFilter = ref<string | null>(typeof q.status === 'string' ? q.status : null)
const sourceLanguageFilter = ref(typeof q.source_language === 'string' ? q.source_language : '')
const targetLanguageFilter = ref<string | null>(typeof q.target_language === 'string' ? q.target_language : null)
const llmProviderFilter = ref<string | null>(typeof q.llm_provider === 'string' ? q.llm_provider : null)
const llmModelFilter = ref(typeof q.llm_model === 'string' ? q.llm_model : '')
const lockedFilter = ref<string | null>(typeof q.locked === 'string' ? q.locked : null)

// Filters panel opens automatically if the URL already carries any filter,
// so a bookmarked/shared link shows what's applied.
showFilters.value = Boolean(
  keyFilter.value ||
    statusFilter.value ||
    sourceLanguageFilter.value ||
    targetLanguageFilter.value ||
    llmProviderFilter.value ||
    llmModelFilter.value ||
    lockedFilter.value,
)

const localeOptions = ref<{ label: string; value: string }[]>([])

const statusOptions = computed(() => [
  { label: t('translations.statusCompleted'), value: 'completed' },
  { label: t('translations.statusPending'), value: 'pending' },
  { label: t('translations.statusFailed'), value: 'failed' },
])

const providerOptions = [
  { label: 'Anthropic', value: 'anthropic' },
  { label: 'OpenAI', value: 'openai' },
  { label: 'Gemini', value: 'gemini' },
  { label: 'Amazon Bedrock', value: 'bedrock' },
  { label: 'Amazon Translate', value: 'aws_translate' },
]

const lockedOptions = computed(() => [
  { label: t('translations.lockedTrue'), value: 'true' },
  { label: t('translations.lockedFalse'), value: 'false' },
])

async function loadLocales() {
  // The filter dropdown needs every locale, not just a page of them - 100 is
  // the API's max page size, comfortably above any real project's count.
  const { locales } = await localesApi.listLocales(auth.token!, project.value!.id, { limit: 100 })
  localeOptions.value = locales.map((l) => ({ label: l.key, value: l.key }))
}

// All-time project total, independent of the list's own filters/pagination.
const usageTotal = ref<TranslationUsageData | null>(null)

async function loadUsageTotal() {
  const { data } = await usageApi.getTranslationUsage(auth.token!, project.value!.id)
  usageTotal.value = data
}

function syncQuery() {
  const query: Record<string, string> = {}
  if (keyFilter.value) query.key = keyFilter.value
  if (statusFilter.value) query.status = statusFilter.value
  if (sourceLanguageFilter.value) query.source_language = sourceLanguageFilter.value
  if (targetLanguageFilter.value) query.target_language = targetLanguageFilter.value
  if (llmProviderFilter.value) query.llm_provider = llmProviderFilter.value
  if (llmModelFilter.value) query.llm_model = llmModelFilter.value
  if (lockedFilter.value) query.locked = lockedFilter.value
  router.replace({ query })
}

async function loadGroups(resetPage = true) {
  if (resetPage) {
    first.value = 0
    selectedKeys.value.clear()
    syncQuery()
  }
  loading.value = true

  const page = await translationsApi.listTranslationGroups(auth.token!, project.value!.id, {
    key: keyFilter.value || undefined,
    status: statusFilter.value || undefined,
    source_language: sourceLanguageFilter.value || undefined,
    target_language: targetLanguageFilter.value || undefined,
    llm_provider: llmProviderFilter.value || undefined,
    llm_model: llmModelFilter.value || undefined,
    locked: lockedFilter.value || undefined,
    offset: first.value,
    limit: PAGE_SIZE,
  })

  groups.value = page.groups
  total.value = page.total
  loading.value = false
}

function onPageChange(event: { first: number }) {
  first.value = event.first
  loadGroups(false)
}

onMounted(() => {
  loadLocales()
  loadGroups()
  loadUsageTotal()
})

function openGroup(group: TranslationGroup) {
  router.push(`/projects/${project.value!.id}/translations/${encodeURIComponent(group.key)}`)
}

const statusSeverity: Record<TranslationSummary['status'], 'success' | 'danger' | 'warn'> = {
  completed: 'success',
  failed: 'danger',
  pending: 'warn',
}

// Overall status for a key across every locale - "partial" flags a key
// where at least one locale succeeded and at least one failed, which is
// easy to miss when only scanning the per-locale tags.
type AggregateStatus = 'completed' | 'pending' | 'failed' | 'partial'

function aggregateStatus(group: TranslationGroup): AggregateStatus {
  const total = group.translations.length
  if (total === 0) return 'pending'

  const completed = group.translations.filter((tr) => tr.status === 'completed').length
  const failed = group.translations.filter((tr) => tr.status === 'failed').length
  const pending = group.translations.filter((tr) => tr.status === 'pending').length

  if (completed === total) return 'completed'
  if (failed === total) return 'failed'
  if (pending === total) return 'pending'
  if (failed > 0) return 'partial'
  return 'pending'
}

const aggregateStatusSeverity: Record<AggregateStatus, 'success' | 'danger' | 'warn'> = {
  completed: 'success',
  pending: 'warn',
  failed: 'danger',
  partial: 'danger',
}

// --- selection + bulk actions ---
const selectedKeys = ref<Set<string>>(new Set())

function toggleSelect(key: string) {
  if (selectedKeys.value.has(key)) {
    selectedKeys.value.delete(key)
  } else {
    selectedKeys.value.add(key)
  }
  selectedKeys.value = new Set(selectedKeys.value)
}

const allSelected = computed(
  () => groups.value.length > 0 && groups.value.every((g) => selectedKeys.value.has(g.key)),
)

function toggleSelectAll() {
  selectedKeys.value = allSelected.value ? new Set() : new Set(groups.value.map((g) => g.key))
}

async function doBulkDelete() {
  const keys = Array.from(selectedKeys.value)
  const { data } = await translationsApi.bulkDeleteTranslations(auth.token!, project.value!.id, keys)

  if (data.skipped.length > 0) {
    toast.add({
      severity: 'warn',
      summary: t('translations.bulkDeleteToastPartial', {
        deleted: data.deleted.length,
        skipped: data.skipped.length,
      }),
      life: 4000,
    })
  } else {
    toast.add({
      severity: 'success',
      summary: t('translations.bulkDeleteToastFull', { count: data.deleted.length }),
      life: 3000,
    })
  }

  await loadGroups()
}

function handleBulkDelete(event: Event) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('translations.bulkDeleteConfirm', { count: selectedKeys.value.size }),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: doBulkDelete,
  })
}

const regenerating = ref(false)

async function doBulkRegenerate() {
  const keys = Array.from(selectedKeys.value)
  regenerating.value = true
  try {
    const { data } = await translationsApi.bulkRegenerateTranslations(auth.token!, project.value!.id, keys)

    if (data.failed.length > 0) {
      toast.add({
        severity: 'warn',
        summary: t('translations.bulkRegenerateToastPartial', {
          regenerated: data.regenerated.length,
          failed: data.failed.length,
        }),
        life: 4000,
      })
    } else {
      toast.add({
        severity: 'success',
        summary: t('translations.bulkRegenerateToastFull', { count: data.regenerated.length }),
        life: 3000,
      })
    }

    await loadGroups()
  } finally {
    regenerating.value = false
  }
}

function handleBulkRegenerate(event: Event) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('translations.bulkRegenerateConfirm', { count: selectedKeys.value.size }),
    icon: 'oi oi-refresh',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('translations.bulkRegenerateAccept') },
    accept: doBulkRegenerate,
  })
}

// --- lock/unlock ---
async function toggleLock(group: TranslationGroup) {
  if (group.locked) {
    await translationsApi.unlockTranslationKey(auth.token!, project.value!.id, group.key)
    group.locked = false
    toast.add({ severity: 'success', summary: t('translations.unlockedToast'), life: 2000 })
  } else {
    await translationsApi.lockTranslationKey(auth.token!, project.value!.id, group.key)
    group.locked = true
    toast.add({ severity: 'success', summary: t('translations.lockedToast'), life: 2000 })
  }
}

// --- export ---
const exportMenu = ref<InstanceType<typeof Menu> | null>(null)
const exportMenuItems = [
  { label: t('translations.exportCsv'), command: () => handleExport('csv') },
  { label: t('translations.exportJson'), command: () => handleExport('json') },
]
const exporting = ref(false)

function toggleExportMenu(event: Event) {
  exportMenu.value?.toggle(event)
}

async function handleExport(format: 'csv' | 'json') {
  exporting.value = true
  try {
    const blob = await translationsApi.exportTranslations(auth.token!, project.value!.id, format)
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `translations-${project.value!.slug}.${format}.gz`
    // The anchor needs to be in the DOM for some browsers to fire the
    // download at all, and revoking the object URL synchronously after
    // click() races the actual save - both silently produce a truncated/
    // empty file rather than an error.
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    setTimeout(() => URL.revokeObjectURL(url), 1000)
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('translations.exportError'),
      life: 4000,
    })
  } finally {
    exporting.value = false
  }
}

// --- import ---
const showImportModal = ref(false)
const importFile = ref<File | null>(null)
const importFormat = ref<'csv' | 'json'>('csv')
const importFormatOptions = [
  { label: 'CSV', value: 'csv' },
  { label: 'JSON', value: 'json' },
]
const importError = ref<string | null>(null)
const importing = ref(false)
const importSummary = ref<ImportSummary | null>(null)

function openImportModal() {
  importFile.value = null
  importFormat.value = 'csv'
  importError.value = null
  importSummary.value = null
  showImportModal.value = true
}

function handleFileChange(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0] ?? null
  importFile.value = file
  if (file && /\.json(\.gz)?$/i.test(file.name)) importFormat.value = 'json'
  else if (file) importFormat.value = 'csv'
}

async function handleImport() {
  importError.value = null
  importSummary.value = null
  if (!importFile.value) {
    importError.value = t('translations.importModal.selectFileFirst')
    return
  }

  importing.value = true
  try {
    const buffer = await importFile.value.arrayBuffer()
    // Gzip magic bytes (1f 8b) - detected from content rather than trusting
    // the filename, since a renamed file would otherwise decode as garbage.
    const compressed = new Uint8Array(buffer.slice(0, 2)).toString() === '31,139'
    const content_base64 = arrayBufferToBase64(buffer)

    const { data } = await translationsApi.importTranslations(auth.token!, project.value!.id, {
      format: importFormat.value,
      content_base64,
      compressed,
    })
    importSummary.value = data
    toast.add({
      severity: 'success',
      summary: t('translations.importModal.summary', {
        created: data.created,
        updated: data.updated,
        skipped: data.skipped.length,
      }),
      life: 4000,
    })
    await loadGroups()
  } catch (e) {
    importError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    importing.value = false
  }
}
</script>

<template>
  <div>
    <div v-if="usageTotal" class="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
      <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
        <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.translations.totalRequests') }}</p>
        <p class="text-2xl font-semibold text-[var(--p-text-color)]">
          {{ usageTotal.total_requests.toLocaleString() }}
        </p>
      </div>
      <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
        <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.translations.cacheHits') }}</p>
        <p class="text-2xl font-semibold text-[var(--p-text-color)]">
          {{ usageTotal.cache_hits.toLocaleString() }}
        </p>
      </div>
      <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
        <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.translations.llmGenerations') }}</p>
        <p class="text-2xl font-semibold text-[var(--p-text-color)]">
          {{ usageTotal.llm_generations.toLocaleString() }}
        </p>
      </div>
    </div>

    <div class="mb-4 flex flex-col gap-3">
      <div class="flex items-end gap-3">
        <Button
          :label="showFilters ? t('translations.hideFilters') : t('translations.filters')"
          text
          severity="secondary"
          icon="oi oi-filter"
          @click="showFilters = !showFilters"
        />
        <div class="flex-1" />
        <Button
          :label="t('translations.export')"
          text
          severity="secondary"
          icon="oi oi-download"
          :loading="exporting"
          aria-haspopup="true"
          @click="toggleExportMenu"
        />
        <Menu ref="exportMenu" :model="exportMenuItems" :popup="true" />
        <Button
          :label="t('translations.import')"
          text
          severity="secondary"
          icon="oi oi-upload"
          @click="openImportModal"
        />
        <template v-if="selectedKeys.size > 0">
          <Button
            :label="t('translations.regenerateSelected', { count: selectedKeys.size })"
            severity="secondary"
            icon="oi oi-refresh"
            :loading="regenerating"
            @click="handleBulkRegenerate"
          />
          <Button
            :label="t('translations.deleteSelected', { count: selectedKeys.size })"
            severity="danger"
            icon="oi oi-trash"
            @click="handleBulkDelete"
          />
        </template>
      </div>

      <div
        v-if="showFilters"
        class="grid grid-cols-2 gap-3 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4 sm:grid-cols-3 lg:grid-cols-7"
      >
        <div>
          <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
            t('translations.filterKeyContains')
          }}</label>
          <InputText
            v-model="keyFilter"
            :placeholder="t('translations.filterKeyPlaceholder')"
            fluid
            @keydown.enter="loadGroups()"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
            t('translations.filterStatus')
          }}</label>
          <Select
            v-model="statusFilter"
            :options="statusOptions"
            option-label="label"
            option-value="value"
            show-clear
            :placeholder="t('common.any')"
            fluid
            @update:model-value="loadGroups()"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
            t('translations.filterSourceLanguage')
          }}</label>
          <InputText
            v-model="sourceLanguageFilter"
            placeholder="en"
            fluid
            @keydown.enter="loadGroups()"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
            t('translations.filterTargetLanguage')
          }}</label>
          <Select
            v-model="targetLanguageFilter"
            :options="localeOptions"
            option-label="label"
            option-value="value"
            show-clear
            :placeholder="t('common.any')"
            fluid
            @update:model-value="loadGroups()"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
            t('translations.filterLlmProvider')
          }}</label>
          <Select
            v-model="llmProviderFilter"
            :options="providerOptions"
            option-label="label"
            option-value="value"
            show-clear
            :placeholder="t('common.any')"
            fluid
            @update:model-value="loadGroups()"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
            t('translations.filterLlmModel')
          }}</label>
          <InputText
            v-model="llmModelFilter"
            placeholder="claude-opus-5"
            fluid
            @keydown.enter="loadGroups()"
          />
        </div>
        <div>
          <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
            t('translations.filterLocked')
          }}</label>
          <Select
            v-model="lockedFilter"
            :options="lockedOptions"
            option-label="label"
            option-value="value"
            show-clear
            :placeholder="t('common.any')"
            fluid
            @update:model-value="loadGroups()"
          />
        </div>
      </div>
    </div>

    <div v-if="loading" class="flex justify-center py-12">
      <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
    </div>

    <EmptyState
      v-else-if="groups.length === 0"
      icon="oi oi-language"
      :message="t('translations.empty')"
      :action-label="t('translations.import')"
      @action="openImportModal"
    />

    <template v-else>
      <div class="mb-2 flex items-center gap-2 px-1">
        <Checkbox :model-value="allSelected" binary @update:model-value="toggleSelectAll" />
        <span class="text-xs text-[var(--p-text-muted-color)]">{{ t('translations.selectAll') }}</span>
      </div>

      <div class="flex flex-col gap-2">
        <div
          v-for="group in groups"
          :key="group.key"
          class="flex items-center gap-3 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] px-4 py-2.5 transition hover:border-[var(--p-primary-color)] hover:shadow-sm"
        >
          <Checkbox
            :model-value="selectedKeys.has(group.key)"
            binary
            @update:model-value="toggleSelect(group.key)"
            @click.stop
          />
          <button
            type="button"
            class="flex min-w-0 flex-1 items-center gap-3 text-left"
            @click="openGroup(group)"
          >
            <Tag
              class="shrink-0"
              :value="aggregateStatus(group)"
              :severity="aggregateStatusSeverity[aggregateStatus(group)]"
            />
            <code class="max-w-[10rem] shrink-0 truncate text-xs text-[var(--p-text-muted-color)]">{{
              group.key
            }}</code>
            <span v-if="group.source_language" class="shrink-0 text-xs text-[var(--p-text-muted-color)]">
              {{ group.source_language }}
            </span>
            <p class="min-w-0 flex-1 truncate text-base font-medium text-[var(--p-text-color)]">
              {{ group.source_text }}
            </p>
            <span
              v-if="group.usage.total_requests > 0"
              class="flex shrink-0 items-center gap-1 text-xs text-[var(--p-text-muted-color)]"
              :title="
                t('translations.usageTooltip', {
                  cached: group.usage.cache_hits,
                  generated: group.usage.llm_generations,
                })
              "
            >
              <i class="oi oi-chart-line" />
              {{ group.usage.total_requests }}
            </span>
            <div class="flex shrink-0 items-center gap-1.5">
              <template v-if="group.translations.length <= LANGUAGE_TAG_THRESHOLD">
                <Tag
                  v-for="tr in group.translations"
                  :key="tr.id"
                  :value="tr.locale"
                  :severity="statusSeverity[tr.status]"
                />
              </template>
              <span v-else class="text-xs text-[var(--p-text-muted-color)]">
                {{ t('translations.languagesCount', { count: group.translations.length }) }}
              </span>
            </div>
          </button>
          <Button
            :icon="group.locked ? 'oi oi-lock' : 'oi oi-unlock'"
            text
            size="small"
            severity="secondary"
            :title="group.locked ? t('translations.unlock') : t('translations.lock')"
            @click="toggleLock(group)"
          />
        </div>
      </div>
    </template>

    <Paginator
      v-if="total > PAGE_SIZE"
      :rows="PAGE_SIZE"
      :total-records="total"
      :first="first"
      class="mt-4"
      @page="onPageChange"
    />

    <Dialog
      v-model:visible="showImportModal"
      modal
      :header="t('translations.importModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleImport">
        <Message v-if="importError" severity="error" :closable="false">{{ importError }}</Message>

        <div class="flex flex-col gap-2">
          <label for="import-file" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('translations.importModal.file')
          }}</label>
          <input
            id="import-file"
            type="file"
            accept=".csv,.json,.gz"
            class="text-sm text-[var(--p-text-color)] file:mr-3 file:rounded-md file:border-0 file:bg-[var(--p-content-hover-background)] file:px-3 file:py-1.5 file:text-sm"
            @change="handleFileChange"
          />
          <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('translations.importModal.fileHint') }}</p>
        </div>

        <div class="flex flex-col gap-2">
          <label for="import-format" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('translations.importModal.format')
          }}</label>
          <Select
            id="import-format"
            v-model="importFormat"
            :options="importFormatOptions"
            option-label="label"
            option-value="value"
            fluid
          />
        </div>

        <div v-if="importSummary" class="flex flex-col gap-1 rounded-md border border-[var(--p-content-border-color)] p-3">
          <p class="text-sm text-[var(--p-text-color)]">
            {{
              t('translations.importModal.summary', {
                created: importSummary.created,
                updated: importSummary.updated,
                skipped: importSummary.skipped.length,
              })
            }}
          </p>
          <p
            v-for="(row, i) in importSummary.skipped"
            :key="i"
            class="text-xs text-[var(--p-text-muted-color)]"
          >
            {{ t('translations.importModal.skippedReason', row) }}
          </p>
        </div>

        <Button type="submit" :label="t('translations.importModal.submit')" :loading="importing" fluid />
      </form>
    </Dialog>
  </div>
</template>
