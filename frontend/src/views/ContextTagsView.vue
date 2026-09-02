<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import Button from 'openvue/button'
import Dialog from 'openvue/dialog'
import InputText from 'openvue/inputtext'
import Textarea from 'openvue/textarea'
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
import * as contextTagsApi from '@/api/contextTags'
import { ApiError } from '@/api/client'
import { arrayBufferToBase64 } from '@/lib/base64'
import type { ContextTag } from '@/api/types'
import type { ContextTagImportSummary } from '@/api/contextTags'

const auth = useAuthStore()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()
const { project } = useProject()

const PAGE_SIZE = 20

const tags = ref<ContextTag[]>([])
const loading = ref(true)
const first = ref(0)
const total = ref(0)

const { filters, showFilters, syncQuery, toParams } = useListFilters({ search: '' })

async function loadTags(resetPage = true) {
  if (resetPage) {
    first.value = 0
    syncQuery()
  }
  loading.value = true

  const { tags: page, total: count } = await contextTagsApi.listContextTags(
    auth.token!,
    project.value!.id,
    { offset: first.value, limit: PAGE_SIZE, ...toParams() },
  )
  tags.value = page
  total.value = count

  loading.value = false
}

function onPageChange(event: { first: number }) {
  first.value = event.first
  loadTags(false)
}

async function reloadFirstPage() {
  first.value = 0
  await loadTags(false)
}

onMounted(loadTags)

// --- create ---
const showCreateModal = ref(false)
const createForm = ref({ key: '', description: '' })
const createError = ref<string | null>(null)
const creating = ref(false)

function openCreateModal() {
  createForm.value = { key: '', description: '' }
  createError.value = null
  showCreateModal.value = true
}

async function handleCreate() {
  createError.value = null
  creating.value = true
  try {
    await contextTagsApi.createContextTag(auth.token!, project.value!.id, {
      key: createForm.value.key,
      description: createForm.value.description || undefined,
    })
    showCreateModal.value = false
    toast.add({ severity: 'success', summary: t('contextTags.createdToast'), life: 3000 })
    await reloadFirstPage()
  } catch (e) {
    createError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    creating.value = false
  }
}

// --- edit ---
const showEditModal = ref(false)
const editingTag = ref<ContextTag | null>(null)
const editForm = ref({ key: '', description: '' })
const editError = ref<string | null>(null)
const saving = ref(false)

function openEditModal(tag: ContextTag) {
  editingTag.value = tag
  editForm.value = { key: tag.key, description: tag.description ?? '' }
  editError.value = null
  showEditModal.value = true
}

async function handleSaveEdit() {
  if (!editingTag.value) return
  editError.value = null
  saving.value = true
  try {
    await contextTagsApi.updateContextTag(auth.token!, project.value!.id, editingTag.value.id, editForm.value)
    showEditModal.value = false
    toast.add({ severity: 'success', summary: t('contextTags.updatedToast'), life: 3000 })
    await loadTags()
  } catch (e) {
    editError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    saving.value = false
  }
}

async function doDelete(tag: ContextTag) {
  try {
    await contextTagsApi.deleteContextTag(auth.token!, project.value!.id, tag.id)
    toast.add({ severity: 'success', summary: t('contextTags.deletedToast'), life: 3000 })
    await reloadFirstPage()
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong'),
      life: 4000,
    })
  }
}

function handleDelete(event: Event, tag: ContextTag) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('contextTags.deleteConfirm'),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: () => doDelete(tag),
  })
}

// --- export ---
const exportMenu = ref<InstanceType<typeof Menu> | null>(null)
const exportMenuItems = [
  { label: t('contextTags.exportCsv'), command: () => handleExport('csv') },
  { label: t('contextTags.exportJson'), command: () => handleExport('json') },
]
const exporting = ref(false)

function toggleExportMenu(event: Event) {
  exportMenu.value?.toggle(event)
}

async function handleExport(format: 'csv' | 'json') {
  exporting.value = true
  try {
    const blob = await contextTagsApi.exportContextTags(auth.token!, project.value!.id, format)
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `context-tags-${project.value!.slug}.${format}.gz`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    setTimeout(() => URL.revokeObjectURL(url), 1000)
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('contextTags.exportError'),
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
const importSummary = ref<ContextTagImportSummary | null>(null)

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
    importError.value = t('contextTags.importModal.selectFileFirst')
    return
  }

  importing.value = true
  try {
    const buffer = await importFile.value.arrayBuffer()
    const compressed = new Uint8Array(buffer.slice(0, 2)).toString() === '31,139'
    const content_base64 = arrayBufferToBase64(buffer)

    const { data } = await contextTagsApi.importContextTags(auth.token!, project.value!.id, {
      format: importFormat.value,
      content_base64,
      compressed,
    })
    importSummary.value = data
    toast.add({
      severity: 'success',
      summary: t('contextTags.importModal.summary', {
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
          {{ t('contextTags.description') }}
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
          :label="t('contextTags.export')"
          text
          severity="secondary"
          icon="oi oi-download"
          :loading="exporting"
          aria-haspopup="true"
          @click="toggleExportMenu"
        />
        <Menu ref="exportMenu" :model="exportMenuItems" :popup="true" />
        <Button
          :label="t('contextTags.import')"
          text
          severity="secondary"
          icon="oi oi-upload"
          @click="openImportModal"
        />
        <Button :label="t('contextTags.newTag')" icon="oi oi-plus" @click="openCreateModal" />
      </div>
    </div>

    <div
      v-if="showFilters"
      class="mb-4 grid grid-cols-1 gap-3 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4 sm:grid-cols-3"
    >
      <div>
        <label class="mb-1 block text-xs text-[var(--p-text-muted-color)]">{{
          t('contextTags.filterSearch')
        }}</label>
        <InputText v-model="filters.search" fluid @keydown.enter="loadTags()" />
      </div>
    </div>

    <div v-if="loading" class="flex justify-center py-12">
      <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
    </div>

    <EmptyState
      v-else-if="tags.length === 0"
      icon="oi oi-tags"
      :message="t('contextTags.empty')"
      :action-label="t('contextTags.newTag')"
      @action="openCreateModal"
    />

    <div v-else class="flex flex-col gap-3">
      <div
        v-for="tag in tags"
        :key="tag.id"
        class="flex flex-col gap-2 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4 sm:flex-row sm:items-start sm:justify-between"
      >
        <div class="flex flex-col gap-1">
          <code class="text-sm font-medium text-[var(--p-text-color)]">{{ tag.key }}</code>
          <p v-if="tag.description" class="text-sm text-[var(--p-text-muted-color)]">{{ tag.description }}</p>
        </div>
        <div class="flex gap-2 self-start">
          <Button
            :label="t('contextTags.edit')"
            text
            size="small"
            severity="secondary"
            @click="openEditModal(tag)"
          />
          <Button
            :label="t('contextTags.delete')"
            text
            size="small"
            severity="danger"
            @click="(e) => handleDelete(e, tag)"
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
      :header="t('contextTags.createModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleCreate">
        <Message v-if="createError" severity="error" :closable="false">{{ createError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="new-key" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('contextTags.createModal.key')
          }}</label>
          <InputText
            id="new-key"
            v-model="createForm.key"
            :placeholder="t('contextTags.createModal.keyPlaceholder')"
            fluid
          />
        </div>
        <div class="flex flex-col gap-2">
          <label for="new-desc" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('contextTags.createModal.description')
          }}</label>
          <Textarea
            id="new-desc"
            v-model="createForm.description"
            rows="2"
            :placeholder="t('contextTags.createModal.descriptionPlaceholder')"
            fluid
          />
        </div>
        <Button type="submit" :label="t('contextTags.createModal.submit')" :loading="creating" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showEditModal"
      modal
      :header="t('contextTags.editModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleSaveEdit">
        <Message v-if="editError" severity="error" :closable="false">{{ editError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="edit-key" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('contextTags.editModal.key')
          }}</label>
          <InputText id="edit-key" v-model="editForm.key" fluid />
        </div>
        <div class="flex flex-col gap-2">
          <label for="edit-desc" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('contextTags.editModal.description')
          }}</label>
          <Textarea id="edit-desc" v-model="editForm.description" rows="2" fluid />
        </div>
        <Button type="submit" :label="t('contextTags.editModal.submit')" :loading="saving" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showImportModal"
      modal
      :header="t('contextTags.importModal.header')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleImport">
        <Message v-if="importError" severity="error" :closable="false">{{ importError }}</Message>

        <div class="flex flex-col gap-2">
          <label for="import-file" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('contextTags.importModal.file')
          }}</label>
          <input
            id="import-file"
            type="file"
            accept=".csv,.json,.gz"
            class="text-sm text-[var(--p-text-color)] file:mr-3 file:rounded-md file:border-0 file:bg-[var(--p-content-hover-background)] file:px-3 file:py-1.5 file:text-sm"
            @change="handleFileChange"
          />
          <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('contextTags.importModal.fileHint') }}</p>
        </div>

        <div class="flex flex-col gap-2">
          <label for="import-format" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('contextTags.importModal.format')
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
              t('contextTags.importModal.summary', {
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
            {{ t('contextTags.importModal.skippedReason', row) }}
          </p>
        </div>

        <Button type="submit" :label="t('contextTags.importModal.submit')" :loading="importing" fluid />
      </form>
    </Dialog>
  </div>
</template>
