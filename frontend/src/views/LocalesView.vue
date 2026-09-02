<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import Button from 'openvue/button'
import Dialog from 'openvue/dialog'
import InputText from 'openvue/inputtext'
import Textarea from 'openvue/textarea'
import Message from 'openvue/message'
import Tag from 'openvue/tag'
import Menu from 'openvue/menu'
import Select from 'openvue/select'
import Checkbox from 'openvue/checkbox'
import Paginator from 'openvue/paginator'
import ProgressSpinner from 'openvue/progressspinner'
import { useToast } from 'openvue/usetoast'
import { useConfirm } from 'openvue/useconfirm'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import { useListFilters } from '@/composables/useListFilters'
import * as localesApi from '@/api/locales'
import { ApiError } from '@/api/client'
import { arrayBufferToBase64 } from '@/lib/base64'
import type { Locale } from '@/api/types'
import type { LocaleImportSummary, BulkTranslateCandidate } from '@/api/locales'

const auth = useAuthStore()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()
const { project } = useProject()

const PAGE_SIZE = 20

const locales = ref<Locale[]>([])
const loading = ref(true)
const first = ref(0)
const total = ref(0)

const { filters, showFilters, syncQuery, toParams } = useListFilters({
  key: '',
  language: '',
  system: '',
})

const systemOptions = computed(() => [
  { label: t('locales.filterSystemOnly'), value: 'true' },
  { label: t('locales.filterCustomOnly'), value: 'false' },
])

async function loadLocales(resetPage = true) {
  if (resetPage) {
    first.value = 0
    syncQuery()
  }
  loading.value = true

  const { locales: page, total: count } = await localesApi.listLocales(
    auth.token!,
    project.value!.id,
    { offset: first.value, limit: PAGE_SIZE, ...toParams() },
  )
  locales.value = page
  total.value = count

  loading.value = false
}

function onPageChange(event: { first: number }) {
  first.value = event.first
  loadLocales(false)
}

async function reloadFirstPage() {
  first.value = 0
  await loadLocales(false)
}

onMounted(loadLocales)

// --- create ---
const showCreateModal = ref(false)
const createForm = ref({
  key: '',
  target_language: '',
  style_tone_text: '',
  general_description: '',
})
const createError = ref<string | null>(null)
const creating = ref(false)

function openCreateModal() {
  createForm.value = { key: '', target_language: '', style_tone_text: '', general_description: '' }
  createError.value = null
  showCreateModal.value = true
}

async function handleCreate() {
  createError.value = null
  creating.value = true
  try {
    await localesApi.createLocale(auth.token!, project.value!.id, {
      key: createForm.value.key,
      target_language: createForm.value.target_language,
      style_tone_text: createForm.value.style_tone_text || undefined,
      general_description: createForm.value.general_description || undefined,
    })
    showCreateModal.value = false
    toast.add({ severity: 'success', summary: t('locales.createdToast'), life: 3000 })
    await reloadFirstPage()
  } catch (e) {
    createError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    creating.value = false
  }
}

// --- edit ---
const showEditModal = ref(false)
const editingLocale = ref<Locale | null>(null)
const editForm = ref({ target_language: '', style_tone_text: '', general_description: '' })
const editError = ref<string | null>(null)
const saving = ref(false)

function openEditModal(locale: Locale) {
  editingLocale.value = locale
  editForm.value = {
    target_language: locale.target_language,
    style_tone_text: locale.style_tone_text ?? '',
    general_description: locale.general_description ?? '',
  }
  editError.value = null
  showEditModal.value = true
}

async function handleSaveEdit() {
  if (!editingLocale.value) return
  editError.value = null
  saving.value = true
  try {
    await localesApi.updateLocale(
      auth.token!,
      project.value!.id,
      editingLocale.value.id,
      editForm.value,
    )
    showEditModal.value = false
    toast.add({ severity: 'success', summary: t('locales.updatedToast'), life: 3000 })
    await loadLocales()
  } catch (e) {
    editError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    saving.value = false
  }
}

async function doDelete(locale: Locale) {
  try {
    await localesApi.deleteLocale(auth.token!, project.value!.id, locale.id)
    toast.add({ severity: 'success', summary: t('locales.deletedToast'), life: 3000 })
    await reloadFirstPage()
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong'),
      life: 4000,
    })
  }
}

function handleDelete(event: Event, locale: Locale) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('locales.deleteConfirm'),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: () => doDelete(locale),
  })
}

// --- export ---
const exportMenu = ref<InstanceType<typeof Menu> | null>(null)
const exportMenuItems = [
  { label: t('locales.exportCsv'), command: () => handleExport('csv') },
  { label: t('locales.exportJson'), command: () => handleExport('json') },
]
const exporting = ref(false)

function toggleExportMenu(event: Event) {
  exportMenu.value?.toggle(event)
}

async function handleExport(format: 'csv' | 'json') {
  exporting.value = true
  try {
    const blob = await localesApi.exportLocales(auth.token!, project.value!.id, format)
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `locales-${project.value!.slug}.${format}.gz`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    setTimeout(() => URL.revokeObjectURL(url), 1000)
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('locales.exportError'),
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
const importSummary = ref<LocaleImportSummary | null>(null)

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
    importError.value = t('locales.importModal.selectFileFirst')
    return
  }

  importing.value = true
  try {
    const buffer = await importFile.value.arrayBuffer()
    const compressed = new Uint8Array(buffer.slice(0, 2)).toString() === '31,139'
    const content_base64 = arrayBufferToBase64(buffer)

    const { data } = await localesApi.importLocales(auth.token!, project.value!.id, {
      format: importFormat.value,
      content_base64,
      compressed,
    })
    importSummary.value = data
    toast.add({
      severity: 'success',
      summary: t('locales.importModal.summary', {
        created: data.created,
        updated: data.updated,
        skipped: data.skipped.length,
      }),
      life: 4000,
    })
    await reloadFirstPage()
  } catch (e) {
    importError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    importing.value = false
  }
}

// --- bulk translate ---
const showBulkTranslateModal = ref(false)
const bulkTranslateTarget = ref<Locale | null>(null)
const bulkCandidates = ref<BulkTranslateCandidate[]>([])
const bulkCandidatesLoading = ref(false)
const selectedBulkKeys = ref<Set<string>>(new Set())
const bulkTranslating = ref(false)
const bulkError = ref<string | null>(null)

const allBulkSelected = computed(
  () => bulkCandidates.value.length > 0 && selectedBulkKeys.value.size === bulkCandidates.value.length,
)

async function openBulkTranslateModal(locale: Locale) {
  bulkTranslateTarget.value = locale
  bulkCandidates.value = []
  selectedBulkKeys.value = new Set()
  bulkError.value = null
  showBulkTranslateModal.value = true
  bulkCandidatesLoading.value = true

  const { data } = await localesApi.getBulkTranslateCandidates(auth.token!, project.value!.id, locale.id)
  bulkCandidates.value = data.candidates
  selectedBulkKeys.value = new Set(data.candidates.map((c) => c.key))
  bulkCandidatesLoading.value = false
}

function toggleBulkKey(key: string) {
  if (selectedBulkKeys.value.has(key)) selectedBulkKeys.value.delete(key)
  else selectedBulkKeys.value.add(key)
}

function toggleSelectAllBulk() {
  selectedBulkKeys.value = allBulkSelected.value ? new Set() : new Set(bulkCandidates.value.map((c) => c.key))
}

async function handleBulkTranslate() {
  if (!bulkTranslateTarget.value) return
  bulkError.value = null
  bulkTranslating.value = true
  try {
    const { data } = await localesApi.bulkTranslateLocale(
      auth.token!,
      project.value!.id,
      bulkTranslateTarget.value.id,
      Array.from(selectedBulkKeys.value),
    )
    const completed = data.filter((item) => item.translations[0]?.status === 'completed').length
    const failed = data.length - completed
    toast.add({
      severity: 'success',
      summary: t('locales.bulkTranslateModal.summary', { completed, failed }),
      life: 4000,
    })
    showBulkTranslateModal.value = false
  } catch (e) {
    bulkError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    bulkTranslating.value = false
  }
}
</script>

<template>
  <div>
    <div class="mb-4 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <p class="text-sm text-[var(--p-text-muted-color)]">
          {{ t('locales.systemNote') }}
        </p>
        <Button
          :label="showFilters ? t('translations.hideFilters') : t('translations.filters')"
          text
          severity="secondary"
          icon="oi oi-filter"
          @click="showFilters = !showFilters"
        />
      </div>
      <div class="flex items-center gap-2">
        <Button
          :label="t('locales.export')"
          text
          severity="secondary"
          icon="oi oi-download"
          :loading="exporting"
          aria-haspopup="true"
          @click="toggleExportMenu"
        />
        <Menu ref="exportMenu" :model="exportMenuItems" :popup="true" />
        <Button
          :label="t('locales.import')"
          text
          severity="secondary"
          icon="oi oi-upload"
          @click="openImportModal"
        />
        <Button :label="t('locales.newLocale')" icon="oi oi-plus" @click="openCreateModal" />
      </div>
    </div>

    <div
      v-if="showFilters"
      class="mb-4 grid grid-cols-1 gap-3 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4 sm:grid-cols-3"
    >
      <div>
        <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
          t('locales.filterKey')
        }}</label>
        <InputText v-model="filters.key" fluid @keydown.enter="loadLocales()" />
      </div>
      <div>
        <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
          t('locales.filterLanguage')
        }}</label>
        <InputText v-model="filters.language" fluid @keydown.enter="loadLocales()" />
      </div>
      <div>
        <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
          t('locales.filterSystem')
        }}</label>
        <Select
          v-model="filters.system"
          :options="systemOptions"
          option-label="label"
          option-value="value"
          show-clear
          :placeholder="t('common.any')"
          fluid
          @update:model-value="loadLocales()"
        />
      </div>
    </div>

    <div v-if="loading" class="flex justify-center py-12">
      <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
    </div>

    <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
      <div
        v-for="locale in locales"
        :key="locale.id"
        class="flex min-w-0 items-center gap-3 py-3 first:pt-0 last:pb-0"
      >
        <code class="w-24 shrink-0 truncate text-sm font-medium text-[var(--p-text-color)]">{{
          locale.key
        }}</code>
        <Tag v-if="locale.system" :value="t('locales.system')" severity="secondary" class="shrink-0" />
        <span class="w-16 shrink-0 truncate text-sm text-[var(--p-text-muted-color)]">{{
          locale.target_language
        }}</span>
        <span class="min-w-0 flex-1 truncate text-sm text-[var(--p-text-muted-color)]">
          {{ [locale.style_tone_text, locale.general_description].filter(Boolean).join(' · ') }}
        </span>
        <div class="flex shrink-0 gap-2">
          <Button
            :label="t('locales.bulkTranslate')"
            icon="oi oi-sparkles"
            text
            size="small"
            severity="secondary"
            @click="openBulkTranslateModal(locale)"
          />
          <template v-if="!locale.system">
            <Button
              :label="t('locales.edit')"
              text
              size="small"
              severity="secondary"
              @click="openEditModal(locale)"
            />
            <Button
              :label="t('locales.delete')"
              text
              size="small"
              severity="danger"
              @click="(e) => handleDelete(e, locale)"
            />
          </template>
        </div>
      </div>
    </div>

    <Paginator
      v-if="total > PAGE_SIZE"
      :rows="PAGE_SIZE"
      :total-records="total"
      :first="first"
      class="mt-4"
      @page="onPageChange"
    />

    <Dialog
      v-model:visible="showCreateModal"
      modal
      :header="t('locales.createModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleCreate">
        <Message v-if="createError" severity="error" :closable="false">{{ createError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="new-key" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.createModal.key')
          }}</label>
          <InputText
            id="new-key"
            v-model="createForm.key"
            :placeholder="t('locales.createModal.keyPlaceholder')"
            fluid
          />
        </div>
        <div class="flex flex-col gap-2">
          <label for="new-lang" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.createModal.targetLanguage')
          }}</label>
          <InputText
            id="new-lang"
            v-model="createForm.target_language"
            :placeholder="t('locales.createModal.targetLanguagePlaceholder')"
            fluid
          />
        </div>
        <div class="flex flex-col gap-2">
          <label for="new-tone" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.createModal.styleTone')
          }}</label>
          <Textarea
            id="new-tone"
            v-model="createForm.style_tone_text"
            rows="2"
            :placeholder="t('locales.createModal.styleTonePlaceholder')"
            fluid
          />
        </div>
        <div class="flex flex-col gap-2">
          <label for="new-desc" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.createModal.description')
          }}</label>
          <Textarea
            id="new-desc"
            v-model="createForm.general_description"
            rows="2"
            :placeholder="t('locales.createModal.descriptionPlaceholder')"
            fluid
          />
        </div>
        <Button type="submit" :label="t('locales.createModal.submit')" :loading="creating" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showEditModal"
      modal
      :header="t('locales.editModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleSaveEdit">
        <Message v-if="editError" severity="error" :closable="false">{{ editError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="edit-lang" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.editModal.targetLanguage')
          }}</label>
          <InputText id="edit-lang" v-model="editForm.target_language" fluid />
        </div>
        <div class="flex flex-col gap-2">
          <label for="edit-tone" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.editModal.styleTone')
          }}</label>
          <Textarea id="edit-tone" v-model="editForm.style_tone_text" rows="2" fluid />
        </div>
        <div class="flex flex-col gap-2">
          <label for="edit-desc" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.editModal.description')
          }}</label>
          <Textarea id="edit-desc" v-model="editForm.general_description" rows="2" fluid />
        </div>
        <Button type="submit" :label="t('locales.editModal.submit')" :loading="saving" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showImportModal"
      modal
      :header="t('locales.importModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleImport">
        <Message v-if="importError" severity="error" :closable="false">{{ importError }}</Message>

        <div class="flex flex-col gap-2">
          <label for="import-file" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.importModal.file')
          }}</label>
          <input
            id="import-file"
            type="file"
            accept=".csv,.json,.gz"
            class="text-sm text-[var(--p-text-color)] file:mr-3 file:rounded-md file:border-0 file:bg-[var(--p-content-hover-background)] file:px-3 file:py-1.5 file:text-sm"
            @change="handleFileChange"
          />
          <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('locales.importModal.fileHint') }}</p>
        </div>

        <div class="flex flex-col gap-2">
          <label for="import-format" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('locales.importModal.format')
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
              t('locales.importModal.summary', {
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
            {{ t('locales.importModal.skippedReason', row) }}
          </p>
        </div>

        <Button type="submit" :label="t('locales.importModal.submit')" :loading="importing" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showBulkTranslateModal"
      modal
      :header="t('locales.bulkTranslateModal.header', { locale: bulkTranslateTarget?.key })"
      class="w-full max-w-lg"
    >
      <div class="flex flex-col gap-4">
        <Message v-if="bulkError" severity="error" :closable="false">{{ bulkError }}</Message>

        <div v-if="bulkCandidatesLoading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
        </div>

        <template v-else-if="bulkCandidates.length === 0">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('locales.bulkTranslateModal.noCandidates') }}</p>
        </template>

        <template v-else>
          <p class="text-sm text-[var(--p-text-muted-color)]">
            {{ t('locales.bulkTranslateModal.description', { total: bulkCandidates.length }) }}
          </p>

          <div class="flex items-center gap-2 border-b border-[var(--p-content-border-color)] pb-2">
            <Checkbox :model-value="allBulkSelected" binary @update:model-value="toggleSelectAllBulk" />
            <span class="text-xs text-[var(--p-text-muted-color)]">{{ t('locales.bulkTranslateModal.selectAll') }}</span>
          </div>

          <div class="flex max-h-72 flex-col gap-1 overflow-y-auto">
            <label
              v-for="candidate in bulkCandidates"
              :key="candidate.key"
              class="flex min-w-0 cursor-pointer items-start gap-2 rounded-md px-2 py-1.5 hover:bg-[var(--p-content-hover-background)]"
            >
              <Checkbox
                :model-value="selectedBulkKeys.has(candidate.key)"
                binary
                @update:model-value="toggleBulkKey(candidate.key)"
              />
              <span class="flex min-w-0 flex-col gap-0.5">
                <code class="truncate text-xs text-[var(--p-text-muted-color)]">{{ candidate.key }}</code>
                <span class="truncate text-sm text-[var(--p-text-color)]">{{ candidate.source_text }}</span>
              </span>
            </label>
          </div>

          <Message severity="warn" :closable="false">
            {{ t('locales.bulkTranslateModal.costWarning', { count: selectedBulkKeys.size }) }}
          </Message>

          <Button
            :label="t('locales.bulkTranslateModal.submit', { count: selectedBulkKeys.size })"
            :disabled="selectedBulkKeys.size === 0"
            :loading="bulkTranslating"
            fluid
            @click="handleBulkTranslate"
          />
        </template>
      </div>
    </Dialog>
  </div>
</template>
