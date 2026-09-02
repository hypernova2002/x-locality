<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import Button from 'openvue/button'
import Dialog from 'openvue/dialog'
import InputText from 'openvue/inputtext'
import Message from 'openvue/message'
import Menu from 'openvue/menu'
import Select from 'openvue/select'
import Paginator from 'openvue/paginator'
import ProgressSpinner from 'openvue/progressspinner'
import EmptyState from '@/components/EmptyState.vue'
import { useToast } from 'openvue/usetoast'
import { useConfirm } from 'openvue/useconfirm'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import { useListFilters } from '@/composables/useListFilters'
import * as glossaryTermsApi from '@/api/glossaryTerms'
import * as localesApi from '@/api/locales'
import { ApiError } from '@/api/client'
import { arrayBufferToBase64 } from '@/lib/base64'
import type { GlossaryTerm } from '@/api/types'
import type { GlossaryTermImportSummary } from '@/api/glossaryTerms'

const auth = useAuthStore()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()
const { project } = useProject()

const PAGE_SIZE = 20
const ALL_LOCALES_VALUE = '__all__'

const terms = ref<GlossaryTerm[]>([])
const loading = ref(true)
const first = ref(0)
const total = ref(0)

const { filters, showFilters, syncQuery, toParams } = useListFilters({
  search: '',
  source_language: '',
  target_locale: '',
})

async function loadTerms(resetPage = true) {
  if (resetPage) {
    first.value = 0
    syncQuery()
  }
  loading.value = true

  const { terms: page, total: count } = await glossaryTermsApi.listGlossaryTerms(
    auth.token!,
    project.value!.id,
    { offset: first.value, limit: PAGE_SIZE, ...toParams() },
  )
  terms.value = page
  total.value = count

  loading.value = false
}

function onPageChange(event: { first: number }) {
  first.value = event.first
  loadTerms(false)
}

async function reloadFirstPage() {
  first.value = 0
  await loadTerms(false)
}

const localeOptions = ref<{ label: string; value: string }[]>([])

async function loadLocales() {
  const { locales } = await localesApi.listLocales(auth.token!, project.value!.id, { limit: 100 })
  localeOptions.value = locales.map((l) => ({ label: l.key, value: l.key }))
}

const targetLocaleSelectOptions = computed(() => [
  { label: t('glossaryTerms.allLocales'), value: ALL_LOCALES_VALUE },
  ...localeOptions.value,
])

onMounted(() => {
  loadTerms()
  loadLocales()
})

// --- create ---
const showCreateModal = ref(false)
const createForm = ref({
  source_term: '',
  source_language: '',
  target_term: '',
  target_locale_key: ALL_LOCALES_VALUE,
})
const createError = ref<string | null>(null)
const creating = ref(false)

function openCreateModal() {
  createForm.value = { source_term: '', source_language: '', target_term: '', target_locale_key: ALL_LOCALES_VALUE }
  createError.value = null
  showCreateModal.value = true
}

async function handleCreate() {
  createError.value = null
  creating.value = true
  try {
    await glossaryTermsApi.createGlossaryTerm(auth.token!, project.value!.id, {
      source_term: createForm.value.source_term,
      source_language: createForm.value.source_language,
      target_term: createForm.value.target_term,
      target_locale_key:
        createForm.value.target_locale_key === ALL_LOCALES_VALUE ? undefined : createForm.value.target_locale_key,
    })
    showCreateModal.value = false
    toast.add({ severity: 'success', summary: t('glossaryTerms.createdToast'), life: 3000 })
    await reloadFirstPage()
  } catch (e) {
    createError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    creating.value = false
  }
}

// --- edit ---
const showEditModal = ref(false)
const editingTerm = ref<GlossaryTerm | null>(null)
const editForm = ref({
  source_term: '',
  source_language: '',
  target_term: '',
  target_locale_key: ALL_LOCALES_VALUE,
})
const editError = ref<string | null>(null)
const saving = ref(false)

function openEditModal(term: GlossaryTerm) {
  editingTerm.value = term
  editForm.value = {
    source_term: term.source_term,
    source_language: term.source_language,
    target_term: term.target_term,
    target_locale_key: term.target_locale ?? ALL_LOCALES_VALUE,
  }
  editError.value = null
  showEditModal.value = true
}

async function handleSaveEdit() {
  if (!editingTerm.value) return
  editError.value = null
  saving.value = true
  try {
    await glossaryTermsApi.updateGlossaryTerm(auth.token!, project.value!.id, editingTerm.value.id, {
      source_term: editForm.value.source_term,
      source_language: editForm.value.source_language,
      target_term: editForm.value.target_term,
      target_locale_key: editForm.value.target_locale_key === ALL_LOCALES_VALUE ? null : editForm.value.target_locale_key,
    })
    showEditModal.value = false
    toast.add({ severity: 'success', summary: t('glossaryTerms.updatedToast'), life: 3000 })
    await loadTerms()
  } catch (e) {
    editError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    saving.value = false
  }
}

async function doDelete(term: GlossaryTerm) {
  try {
    await glossaryTermsApi.deleteGlossaryTerm(auth.token!, project.value!.id, term.id)
    toast.add({ severity: 'success', summary: t('glossaryTerms.deletedToast'), life: 3000 })
    await reloadFirstPage()
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong'),
      life: 4000,
    })
  }
}

function handleDelete(event: Event, term: GlossaryTerm) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('glossaryTerms.deleteConfirm'),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: () => doDelete(term),
  })
}

// --- export ---
const exportMenu = ref<InstanceType<typeof Menu> | null>(null)
const exportMenuItems = [
  { label: t('glossaryTerms.exportCsv'), command: () => handleExport('csv') },
  { label: t('glossaryTerms.exportJson'), command: () => handleExport('json') },
]
const exporting = ref(false)

function toggleExportMenu(event: Event) {
  exportMenu.value?.toggle(event)
}

async function handleExport(format: 'csv' | 'json') {
  exporting.value = true
  try {
    const blob = await glossaryTermsApi.exportGlossaryTerms(auth.token!, project.value!.id, format)
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `glossary-${project.value!.slug}.${format}.gz`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    setTimeout(() => URL.revokeObjectURL(url), 1000)
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('glossaryTerms.exportError'),
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
const importSummary = ref<GlossaryTermImportSummary | null>(null)

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
    importError.value = t('glossaryTerms.importModal.selectFileFirst')
    return
  }

  importing.value = true
  try {
    const buffer = await importFile.value.arrayBuffer()
    const compressed = new Uint8Array(buffer.slice(0, 2)).toString() === '31,139'
    const content_base64 = arrayBufferToBase64(buffer)

    const { data } = await glossaryTermsApi.importGlossaryTerms(auth.token!, project.value!.id, {
      format: importFormat.value,
      content_base64,
      compressed,
    })
    importSummary.value = data
    toast.add({
      severity: 'success',
      summary: t('glossaryTerms.importModal.summary', {
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
</script>

<template>
  <div>
    <div class="mb-4 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <p class="text-sm text-[var(--p-text-muted-color)]">
          {{ t('glossaryTerms.description') }}
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
          :label="t('glossaryTerms.export')"
          text
          severity="secondary"
          icon="oi oi-download"
          :loading="exporting"
          aria-haspopup="true"
          @click="toggleExportMenu"
        />
        <Menu ref="exportMenu" :model="exportMenuItems" :popup="true" />
        <Button
          :label="t('glossaryTerms.import')"
          text
          severity="secondary"
          icon="oi oi-upload"
          @click="openImportModal"
        />
        <Button :label="t('glossaryTerms.newTerm')" icon="oi oi-plus" @click="openCreateModal" />
      </div>
    </div>

    <div
      v-if="showFilters"
      class="mb-4 grid grid-cols-1 gap-3 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4 sm:grid-cols-3"
    >
      <div>
        <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
          t('glossaryTerms.filterSearch')
        }}</label>
        <InputText v-model="filters.search" fluid @keydown.enter="loadTerms()" />
      </div>
      <div>
        <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
          t('glossaryTerms.filterSourceLanguage')
        }}</label>
        <InputText v-model="filters.source_language" fluid @keydown.enter="loadTerms()" />
      </div>
      <div>
        <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
          t('glossaryTerms.filterTargetLocale')
        }}</label>
        <Select
          v-model="filters.target_locale"
          :options="localeOptions"
          option-label="label"
          option-value="value"
          show-clear
          :placeholder="t('common.any')"
          fluid
          @update:model-value="loadTerms()"
        />
      </div>
    </div>

    <div v-if="loading" class="flex justify-center py-12">
      <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
    </div>

    <EmptyState
      v-else-if="terms.length === 0"
      icon="oi oi-language"
      :message="t('glossaryTerms.empty')"
      :action-label="t('glossaryTerms.newTerm')"
      @action="openCreateModal"
    />

    <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
      <div
        v-for="term in terms"
        :key="term.id"
        class="flex min-w-0 items-center gap-3 py-3 first:pt-0 last:pb-0"
      >
        <code class="w-32 shrink-0 truncate text-sm font-medium text-[var(--p-text-color)]">{{
          term.source_term
        }}</code>
        <span class="w-10 shrink-0 truncate text-xs text-[var(--p-text-muted-color)]">{{
          term.source_language
        }}</span>
        <i class="oi oi-arrow-right shrink-0 text-xs text-[var(--p-text-muted-color)]" />
        <code class="w-32 shrink-0 truncate text-sm text-[var(--p-text-color)]">{{ term.target_term }}</code>
        <span class="min-w-0 flex-1 truncate text-xs text-[var(--p-text-muted-color)]">
          {{ term.target_locale ?? t('glossaryTerms.allLocales') }}
        </span>
        <div class="flex shrink-0 gap-2">
          <Button
            :label="t('glossaryTerms.edit')"
            text
            size="small"
            severity="secondary"
            @click="openEditModal(term)"
          />
          <Button
            :label="t('glossaryTerms.delete')"
            text
            size="small"
            severity="danger"
            @click="(e) => handleDelete(e, term)"
          />
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
      :header="t('glossaryTerms.createModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleCreate">
        <Message v-if="createError" severity="error" :closable="false">{{ createError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="new-source-term" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.createModal.sourceTerm')
          }}</label>
          <InputText
            id="new-source-term"
            v-model="createForm.source_term"
            :placeholder="t('glossaryTerms.createModal.sourceTermPlaceholder')"
            fluid
          />
        </div>
        <div class="flex flex-col gap-2">
          <label for="new-source-lang" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.createModal.sourceLanguage')
          }}</label>
          <InputText
            id="new-source-lang"
            v-model="createForm.source_language"
            :placeholder="t('glossaryTerms.createModal.sourceLanguagePlaceholder')"
            fluid
          />
        </div>
        <div class="flex flex-col gap-2">
          <label for="new-target-term" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.createModal.targetTerm')
          }}</label>
          <InputText
            id="new-target-term"
            v-model="createForm.target_term"
            :placeholder="t('glossaryTerms.createModal.targetTermPlaceholder')"
            fluid
          />
        </div>
        <div class="flex flex-col gap-2">
          <label for="new-target-locale" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.createModal.targetLocale')
          }}</label>
          <Select
            id="new-target-locale"
            v-model="createForm.target_locale_key"
            :options="targetLocaleSelectOptions"
            option-label="label"
            option-value="value"
            fluid
          />
          <p class="text-xs text-[var(--p-text-muted-color)]">
            {{ t('glossaryTerms.createModal.targetLocaleHint') }}
          </p>
        </div>
        <Button type="submit" :label="t('glossaryTerms.createModal.submit')" :loading="creating" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showEditModal"
      modal
      :header="t('glossaryTerms.editModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleSaveEdit">
        <Message v-if="editError" severity="error" :closable="false">{{ editError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="edit-source-term" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.editModal.sourceTerm')
          }}</label>
          <InputText id="edit-source-term" v-model="editForm.source_term" fluid />
        </div>
        <div class="flex flex-col gap-2">
          <label for="edit-source-lang" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.editModal.sourceLanguage')
          }}</label>
          <InputText id="edit-source-lang" v-model="editForm.source_language" fluid />
        </div>
        <div class="flex flex-col gap-2">
          <label for="edit-target-term" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.editModal.targetTerm')
          }}</label>
          <InputText id="edit-target-term" v-model="editForm.target_term" fluid />
        </div>
        <div class="flex flex-col gap-2">
          <label for="edit-target-locale" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.editModal.targetLocale')
          }}</label>
          <Select
            id="edit-target-locale"
            v-model="editForm.target_locale_key"
            :options="targetLocaleSelectOptions"
            option-label="label"
            option-value="value"
            fluid
          />
        </div>
        <Button type="submit" :label="t('glossaryTerms.editModal.submit')" :loading="saving" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showImportModal"
      modal
      :header="t('glossaryTerms.importModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleImport">
        <Message v-if="importError" severity="error" :closable="false">{{ importError }}</Message>

        <div class="flex flex-col gap-2">
          <label for="import-file" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.importModal.file')
          }}</label>
          <input
            id="import-file"
            type="file"
            accept=".csv,.json,.gz"
            class="text-sm text-[var(--p-text-color)] file:mr-3 file:rounded-md file:border-0 file:bg-[var(--p-content-hover-background)] file:px-3 file:py-1.5 file:text-sm"
            @change="handleFileChange"
          />
          <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('glossaryTerms.importModal.fileHint') }}</p>
        </div>

        <div class="flex flex-col gap-2">
          <label for="import-format" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('glossaryTerms.importModal.format')
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
              t('glossaryTerms.importModal.summary', {
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
            {{ t('glossaryTerms.importModal.skippedReason', row) }}
          </p>
        </div>

        <Button type="submit" :label="t('glossaryTerms.importModal.submit')" :loading="importing" fluid />
      </form>
    </Dialog>
  </div>
</template>
