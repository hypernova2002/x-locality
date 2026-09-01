<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import Card from 'openvue/card'
import Button from 'openvue/button'
import Dialog from 'openvue/dialog'
import InputText from 'openvue/inputtext'
import Checkbox from 'openvue/checkbox'
import ToggleSwitch from 'openvue/toggleswitch'
import Tag from 'openvue/tag'
import Message from 'openvue/message'
import Paginator from 'openvue/paginator'
import ProgressSpinner from 'openvue/progressspinner'
import EmptyState from '@/components/EmptyState.vue'
import { useToast } from 'openvue/usetoast'
import { useConfirm } from 'openvue/useconfirm'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import * as webhooksApi from '@/api/webhooks'
import { ApiError } from '@/api/client'
import { formatDateTime } from '@/lib/formatDate'
import type { ProjectWebhook, WebhookDelivery, WebhookEventType } from '@/api/types'

const auth = useAuthStore()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()
const { project } = useProject()

const EVENT_TYPES: WebhookEventType[] = ['translation.batch_completed', 'budget.threshold_crossed']

const PAGE_SIZE = 20

const webhooks = ref<ProjectWebhook[]>([])
const loading = ref(true)
const first = ref(0)
const total = ref(0)
const revealedSecrets = ref<Set<string>>(new Set())

async function loadWebhooks() {
  loading.value = true
  const { webhooks: page, total: count } = await webhooksApi.listWebhooks(auth.token!, project.value!.id, {
    offset: first.value,
    limit: PAGE_SIZE,
  })
  webhooks.value = page
  total.value = count
  loading.value = false
}

function onPageChange(event: { first: number }) {
  first.value = event.first
  loadWebhooks()
}

async function reloadFirstPage() {
  first.value = 0
  await loadWebhooks()
}

onMounted(loadWebhooks)

function toggleReveal(id: string) {
  if (revealedSecrets.value.has(id)) revealedSecrets.value.delete(id)
  else revealedSecrets.value.add(id)
}

async function copySecret(secret: string) {
  await navigator.clipboard.writeText(secret)
  toast.add({ severity: 'success', summary: t('common.copiedToClipboard'), life: 2000 })
}

// --- create/edit ---
const showFormModal = ref(false)
const editingWebhook = ref<ProjectWebhook | null>(null)
const form = ref({ url: '', event_types: [] as WebhookEventType[] })
const formError = ref<string | null>(null)
const saving = ref(false)

function openCreateModal() {
  editingWebhook.value = null
  form.value = { url: '', event_types: [] }
  formError.value = null
  showFormModal.value = true
}

function openEditModal(webhook: ProjectWebhook) {
  editingWebhook.value = webhook
  form.value = { url: webhook.url, event_types: [...webhook.event_types] }
  formError.value = null
  showFormModal.value = true
}

function toggleEventType(eventType: WebhookEventType) {
  const idx = form.value.event_types.indexOf(eventType)
  if (idx === -1) form.value.event_types.push(eventType)
  else form.value.event_types.splice(idx, 1)
}

async function handleSave() {
  formError.value = null
  saving.value = true
  try {
    if (editingWebhook.value) {
      await webhooksApi.updateWebhook(auth.token!, project.value!.id, editingWebhook.value.id, {
        url: form.value.url,
        event_types: form.value.event_types,
      })
      toast.add({ severity: 'success', summary: t('settings.webhooks.updatedToast'), life: 3000 })
      await loadWebhooks()
    } else {
      await webhooksApi.createWebhook(auth.token!, project.value!.id, {
        url: form.value.url,
        event_types: form.value.event_types,
      })
      toast.add({ severity: 'success', summary: t('settings.webhooks.createdToast'), life: 3000 })
      await reloadFirstPage()
    }
    showFormModal.value = false
  } catch (e) {
    formError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    saving.value = false
  }
}

async function handleToggleEnabled(webhook: ProjectWebhook) {
  await webhooksApi.updateWebhook(auth.token!, project.value!.id, webhook.id, { enabled: !webhook.enabled })
  await loadWebhooks()
}

async function doDelete(webhook: ProjectWebhook) {
  try {
    await webhooksApi.deleteWebhook(auth.token!, project.value!.id, webhook.id)
    toast.add({ severity: 'success', summary: t('settings.webhooks.deletedToast'), life: 3000 })
    await reloadFirstPage()
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong'),
      life: 4000,
    })
  }
}

function handleDelete(event: Event, webhook: ProjectWebhook) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('settings.webhooks.deleteConfirm'),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: () => doDelete(webhook),
  })
}

// --- test ---
const testingId = ref<string | null>(null)

async function handleTest(webhook: ProjectWebhook) {
  testingId.value = webhook.id
  try {
    await webhooksApi.testWebhook(auth.token!, project.value!.id, webhook.id)
    toast.add({ severity: 'success', summary: t('settings.webhooks.testSentToast'), life: 3000 })
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('settings.webhooks.testFailedToast'),
      life: 4000,
    })
  } finally {
    testingId.value = null
  }
}

// --- deliveries ---
const showDeliveriesModal = ref(false)
const deliveriesWebhook = ref<ProjectWebhook | null>(null)
const deliveries = ref<WebhookDelivery[]>([])
const deliveriesLoading = ref(false)

async function openDeliveriesModal(webhook: ProjectWebhook) {
  deliveriesWebhook.value = webhook
  deliveries.value = []
  showDeliveriesModal.value = true
  deliveriesLoading.value = true
  const { deliveries: page } = await webhooksApi.listWebhookDeliveries(auth.token!, project.value!.id, webhook.id, {
    limit: 20,
  })
  deliveries.value = page
  deliveriesLoading.value = false
}
</script>

<template>
  <Card>
    <template #title>
      <div class="flex items-center justify-between">
        <span>{{ t('settings.webhooks.cardTitle') }}</span>
        <Button :label="t('settings.webhooks.newWebhook')" icon="oi oi-plus" size="small" @click="openCreateModal" />
      </div>
    </template>
    <template #content>
      <p class="mb-4 text-sm text-[var(--p-text-muted-color)]">{{ t('settings.webhooks.description') }}</p>

      <div v-if="loading" class="flex justify-center py-8">
        <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
      </div>

      <EmptyState
        v-else-if="webhooks.length === 0"
        icon="oi oi-bolt"
        :message="t('settings.webhooks.empty')"
        :action-label="t('settings.webhooks.newWebhook')"
        @action="openCreateModal"
      />

      <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
        <div v-for="webhook in webhooks" :key="webhook.id" class="flex flex-col gap-2 py-3 first:pt-0 last:pb-0">
          <div class="flex min-w-0 items-center gap-3">
            <code class="min-w-0 flex-1 truncate text-sm text-[var(--p-text-color)]">{{ webhook.url }}</code>
            <ToggleSwitch :model-value="webhook.enabled" class="shrink-0" @update:model-value="handleToggleEnabled(webhook)" />
          </div>

          <div class="flex flex-wrap items-center gap-1.5">
            <Tag v-for="eventType in webhook.event_types" :key="eventType" :value="eventType" severity="secondary" />
          </div>

          <div class="flex items-center gap-2">
            <code v-if="revealedSecrets.has(webhook.id)" class="min-w-0 truncate text-xs text-[var(--p-text-muted-color)]">{{
              webhook.secret
            }}</code>
            <code v-else class="text-xs text-[var(--p-text-muted-color)]">••••••••••••••••</code>
            <Button
              :icon="revealedSecrets.has(webhook.id) ? 'oi oi-eye-slash' : 'oi oi-eye'"
              text
              size="small"
              severity="secondary"
              class="shrink-0"
              @click="toggleReveal(webhook.id)"
            />
            <Button
              icon="oi oi-copy"
              text
              size="small"
              severity="secondary"
              class="shrink-0"
              @click="copySecret(webhook.secret)"
            />
          </div>

          <div class="flex items-center gap-1">
            <Button
              :label="t('settings.webhooks.test')"
              text
              size="small"
              severity="secondary"
              :loading="testingId === webhook.id"
              @click="handleTest(webhook)"
            />
            <Button
              :label="t('settings.webhooks.deliveries')"
              text
              size="small"
              severity="secondary"
              @click="openDeliveriesModal(webhook)"
            />
            <Button
              :label="t('settings.webhooks.edit')"
              text
              size="small"
              severity="secondary"
              @click="openEditModal(webhook)"
            />
            <Button
              :label="t('settings.webhooks.delete')"
              text
              size="small"
              severity="danger"
              @click="(e) => handleDelete(e, webhook)"
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
    </template>
  </Card>

  <Dialog
    v-model:visible="showFormModal"
    modal
    :header="editingWebhook ? t('settings.webhooks.editModal.header') : t('settings.webhooks.createModal.header')"
    class="w-full max-w-md"
  >
    <form class="flex flex-col gap-4" @submit.prevent="handleSave">
      <Message v-if="formError" severity="error" :closable="false">{{ formError }}</Message>

      <div class="flex flex-col gap-2">
        <label for="webhook-url" class="text-sm font-medium text-[var(--p-text-color)]">{{
          t('settings.webhooks.formModal.url')
        }}</label>
        <InputText id="webhook-url" v-model="form.url" placeholder="https://example.com/webhooks/x-locality" fluid />
      </div>

      <div class="flex flex-col gap-2">
        <span class="text-sm font-medium text-[var(--p-text-color)]">{{
          t('settings.webhooks.formModal.eventTypes')
        }}</span>
        <label
          v-for="eventType in EVENT_TYPES"
          :key="eventType"
          class="flex items-center gap-2 text-sm text-[var(--p-text-color)]"
        >
          <Checkbox
            :model-value="form.event_types.includes(eventType)"
            binary
            @update:model-value="toggleEventType(eventType)"
          />
          {{ t(`settings.webhooks.eventTypes.${eventType}`) }}
        </label>
      </div>

      <Button type="submit" :label="t('settings.webhooks.formModal.submit')" :loading="saving" fluid />
    </form>
  </Dialog>

  <Dialog
    v-model:visible="showDeliveriesModal"
    modal
    :header="t('settings.webhooks.deliveriesModal.header')"
    class="w-full max-w-lg"
  >
    <div v-if="deliveriesLoading" class="flex justify-center py-8">
      <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
    </div>
    <p v-else-if="deliveries.length === 0" class="text-sm text-[var(--p-text-muted-color)]">
      {{ t('settings.webhooks.deliveriesModal.empty') }}
    </p>
    <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
      <div v-for="delivery in deliveries" :key="delivery.id" class="flex flex-col gap-1 py-2.5 first:pt-0 last:pb-0">
        <div class="flex items-center gap-2">
          <Tag :value="delivery.success ? t('settings.webhooks.deliveriesModal.success') : t('settings.webhooks.deliveriesModal.failed')" :severity="delivery.success ? 'success' : 'danger'" />
          <span class="text-xs text-[var(--p-text-muted-color)]">{{ delivery.event_type }}</span>
          <span v-if="delivery.response_status" class="text-xs text-[var(--p-text-muted-color)]"
            >HTTP {{ delivery.response_status }}</span
          >
          <span class="ml-auto shrink-0 text-xs text-[var(--p-text-muted-color)]">{{
            formatDateTime(delivery.created_at)
          }}</span>
        </div>
        <p v-if="delivery.error_message" class="text-xs text-red-600">{{ delivery.error_message }}</p>
      </div>
    </div>
  </Dialog>
</template>
