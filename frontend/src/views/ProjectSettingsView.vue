<script setup lang="ts">
import { ref, watch, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import Card from 'openvue/card'
import InputText from 'openvue/inputtext'
import InputNumber from 'openvue/inputnumber'
import Select from 'openvue/select'
import Password from 'openvue/password'
import ToggleSwitch from 'openvue/toggleswitch'
import Button from 'openvue/button'
import Dialog from 'openvue/dialog'
import Message from 'openvue/message'
import Tag from 'openvue/tag'
import Paginator from 'openvue/paginator'
import ProgressSpinner from 'openvue/progressspinner'
import Tabs from 'openvue/tabs'
import TabList from 'openvue/tablist'
import Tab from 'openvue/tab'
import TabPanels from 'openvue/tabpanels'
import TabPanel from 'openvue/tabpanel'
import EmptyState from '@/components/EmptyState.vue'
import ProjectMembersView from './ProjectMembersView.vue'
import ProjectWebhooksView from './ProjectWebhooksView.vue'
import { useToast } from 'openvue/usetoast'
import { useConfirm } from 'openvue/useconfirm'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import * as projectsApi from '@/api/projects'
import * as llmConfigApi from '@/api/llmConfig'
import * as llmProviderConfigsApi from '@/api/llmProviderConfigs'
import * as apiKeysApi from '@/api/apiKeys'
import { ApiError } from '@/api/client'
import { formatDateTime } from '@/lib/formatDate'
import type { ApiKey, LlmConfig, LlmModelOption, LlmProviderConfig } from '@/api/types'

const auth = useAuthStore()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()
const { project, reloadProject } = useProject()

const activeTab = ref('general')

// --- project name ---
const name = ref('')
const error = ref<string | null>(null)
const saving = ref(false)

watch(
  project,
  (p) => {
    if (p) name.value = p.name
  },
  { immediate: true },
)

async function handleSave() {
  error.value = null
  saving.value = true
  try {
    await projectsApi.updateProject(auth.token!, project.value!.id, { name: name.value })
    toast.add({ severity: 'success', summary: t('settings.project.savedToast'), life: 3000 })
    await reloadProject()
  } catch (e) {
    error.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    saving.value = false
  }
}

// --- LLM provider configs (the saved, reusable list) ---
const providerConfigs = ref<LlmProviderConfig[]>([])
const providerConfigsLoading = ref(true)

async function loadProviderConfigs() {
  providerConfigsLoading.value = true
  const { data } = await llmProviderConfigsApi.listLlmProviderConfigs(auth.token!, project.value!.id)
  providerConfigs.value = data
  providerConfigsLoading.value = false
}

onMounted(loadProviderConfigs)

// --- project-level LLM settings: active config + budgets ---
const llmConfig = ref<LlmConfig | null>(null)
const llmConfigLoading = ref(true)
const activeConfigId = ref<string | null>(null)
const monthlyCostLimit = ref<number | null>(null)
const monthlyTokenLimit = ref<number | null>(null)
const alertEmail = ref('')
const alertThresholdPercent = ref<number | null>(null)
const langfuseEnabled = ref(false)
const langfusePublicKey = ref('')
const langfuseSecretKey = ref('')
const llmError = ref<string | null>(null)
const llmSaving = ref(false)

const activeConfigOptions = computed(() =>
  providerConfigs.value.map((c) => ({ label: `${c.name} (${c.provider})`, value: c.id })),
)

async function loadLlmConfig() {
  llmConfigLoading.value = true
  const { data } = await llmConfigApi.getLlmConfig(auth.token!, project.value!.id)
  llmConfig.value = data
  activeConfigId.value = data.active_llm_provider_config_id
  monthlyCostLimit.value = data.monthly_cost_limit_usd
  monthlyTokenLimit.value = data.monthly_token_limit
  alertEmail.value = data.alert_email ?? ''
  alertThresholdPercent.value = data.alert_threshold_percent
  langfuseEnabled.value = data.langfuse_enabled
  langfusePublicKey.value = data.langfuse_public_key ?? ''
  langfuseSecretKey.value = ''
  llmConfigLoading.value = false
}

onMounted(loadLlmConfig)

async function handleSaveLlm() {
  llmError.value = null
  llmSaving.value = true
  try {
    const params: Parameters<typeof llmConfigApi.updateLlmConfig>[2] = {
      active_llm_provider_config_id: activeConfigId.value,
      monthly_cost_limit_usd: monthlyCostLimit.value,
      monthly_token_limit: monthlyTokenLimit.value,
      alert_email: alertEmail.value || null,
      alert_threshold_percent: alertThresholdPercent.value,
      langfuse_enabled: langfuseEnabled.value,
      langfuse_public_key: langfusePublicKey.value || null,
    }
    // Blank means "leave the currently-saved secret alone" - only send a
    // new value when the user actually typed one into the masked field.
    if (langfuseSecretKey.value) params.langfuse_secret_key = langfuseSecretKey.value

    const { data } = await llmConfigApi.updateLlmConfig(auth.token!, project.value!.id, params)
    llmConfig.value = data
    langfuseSecretKey.value = ''
    toast.add({ severity: 'success', summary: t('settings.llm.savedToast'), life: 3000 })
  } catch (e) {
    llmError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    llmSaving.value = false
  }
}

const testingAlert = ref(false)

async function handleTestAlert() {
  testingAlert.value = true
  try {
    await llmConfigApi.testLlmAlert(auth.token!, project.value!.id)
    toast.add({ severity: 'success', summary: t('settings.llm.testAlertSentToast'), life: 3000 })
  } catch (e) {
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong'),
      life: 4000,
    })
  } finally {
    testingAlert.value = false
  }
}

async function setActiveConfig(config: LlmProviderConfig) {
  activeConfigId.value = config.id
  const { data } = await llmConfigApi.updateLlmConfig(auth.token!, project.value!.id, {
    active_llm_provider_config_id: config.id,
  })
  llmConfig.value = data
  toast.add({
    severity: 'success',
    summary: t('settings.llm.configActiveToast', { name: config.name }),
    life: 3000,
  })
}

// --- LLM provider config create/edit dialog ---
const showConfigModal = ref(false)
const editingConfig = ref<LlmProviderConfig | null>(null)
const configName = ref('')
const configDescription = ref('')
const configProvider = ref('anthropic')
const configModel = ref<string | null>(null)
const configApiKey = ref('')
const configApiSecret = ref('')
const configRegion = ref('')
const configError = ref<string | null>(null)
const configSaving = ref(false)

const providerOptions = [
  { label: 'Anthropic', value: 'anthropic' },
  { label: 'OpenAI', value: 'openai' },
  { label: 'Gemini', value: 'gemini' },
  { label: 'Amazon Bedrock', value: 'bedrock' },
  { label: 'Amazon Translate', value: 'aws_translate' },
]

const AWS_PROVIDERS = ['bedrock', 'aws_translate']
const isAwsProvider = computed(() => AWS_PROVIDERS.includes(configProvider.value))
const supportsModelSelection = computed(() => configProvider.value !== 'aws_translate')

const availableModels = ref<LlmModelOption[]>([])
const modelsLoading = ref(false)
const modelsError = ref<string | null>(null)

watch(configProvider, () => {
  availableModels.value = []
  modelsError.value = null
  if (!supportsModelSelection.value) configModel.value = null
})

function openCreateModal() {
  editingConfig.value = null
  configName.value = ''
  configDescription.value = ''
  configProvider.value = 'anthropic'
  configModel.value = null
  configApiKey.value = ''
  configApiSecret.value = ''
  configRegion.value = ''
  configError.value = null
  availableModels.value = []
  modelsError.value = null
  showConfigModal.value = true
}

function openEditModal(config: LlmProviderConfig) {
  editingConfig.value = config
  configName.value = config.name
  configDescription.value = config.description ?? ''
  configProvider.value = config.provider
  configModel.value = config.model
  configApiKey.value = ''
  configApiSecret.value = ''
  configRegion.value = config.region ?? ''
  configError.value = null
  availableModels.value = []
  modelsError.value = null
  showConfigModal.value = true
}

async function handleFetchModels() {
  modelsError.value = null
  modelsLoading.value = true
  try {
    const { data } = await llmProviderConfigsApi.listModelsFor(auth.token!, project.value!.id, {
      provider: configProvider.value,
      api_key: configApiKey.value,
      ...(isAwsProvider.value ? { api_secret: configApiSecret.value, region: configRegion.value } : {}),
    })
    availableModels.value = data
  } catch (e) {
    modelsError.value = e instanceof ApiError ? e.detail || e.title : t('settings.llmProviders.modal.fetchModelsError')
  } finally {
    modelsLoading.value = false
  }
}

async function handleSaveConfig() {
  configError.value = null
  configSaving.value = true
  try {
    if (editingConfig.value) {
      const params: Record<string, unknown> = {
        name: configName.value,
        description: configDescription.value || null,
        provider: configProvider.value,
        model: configModel.value,
        region: configRegion.value || null,
      }
      if (configApiKey.value) params.api_key = configApiKey.value
      if (configApiSecret.value) params.api_secret = configApiSecret.value
      await llmProviderConfigsApi.updateLlmProviderConfig(
        auth.token!,
        project.value!.id,
        editingConfig.value.id,
        params,
      )
    } else {
      await llmProviderConfigsApi.createLlmProviderConfig(auth.token!, project.value!.id, {
        name: configName.value,
        description: configDescription.value || undefined,
        provider: configProvider.value,
        model: configModel.value || undefined,
        api_key: configApiKey.value || undefined,
        api_secret: configApiSecret.value || undefined,
        region: configRegion.value || undefined,
      })
    }
    showConfigModal.value = false
    toast.add({ severity: 'success', summary: t('settings.llmProviders.savedToast'), life: 3000 })
    await loadProviderConfigs()
  } catch (e) {
    configError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    configSaving.value = false
  }
}

async function doDeleteConfig(config: LlmProviderConfig) {
  await llmProviderConfigsApi.deleteLlmProviderConfig(auth.token!, project.value!.id, config.id)
  if (activeConfigId.value === config.id) activeConfigId.value = null
  toast.add({ severity: 'success', summary: t('settings.llmProviders.deletedToast'), life: 3000 })
  await loadProviderConfigs()
}

function handleDeleteConfig(event: Event, config: LlmProviderConfig) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message:
      activeConfigId.value === config.id
        ? t('settings.llmProviders.deleteActiveConfirm')
        : t('settings.llmProviders.deleteConfirm', { name: config.name }),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: () => doDeleteConfig(config),
  })
}

// --- API keys ---
const API_KEYS_PAGE_SIZE = 20

const apiKeys = ref<ApiKey[]>([])
const apiKeysLoading = ref(true)
const apiKeysFirst = ref(0)
const apiKeysTotal = ref(0)
const showCreateKeyModal = ref(false)
const newKeyName = ref('')
const createKeyError = ref<string | null>(null)
const creatingKey = ref(false)
const revealedKeys = ref<Set<string>>(new Set())

async function loadApiKeys() {
  apiKeysLoading.value = true

  const { keys, total } = await apiKeysApi.listApiKeys(auth.token!, project.value!.id, {
    offset: apiKeysFirst.value,
    limit: API_KEYS_PAGE_SIZE,
  })
  apiKeys.value = keys
  apiKeysTotal.value = total

  apiKeysLoading.value = false
}

function onApiKeysPageChange(event: { first: number }) {
  apiKeysFirst.value = event.first
  loadApiKeys()
}

async function reloadApiKeysFirstPage() {
  apiKeysFirst.value = 0
  await loadApiKeys()
}

onMounted(loadApiKeys)

function toggleReveal(keyId: string) {
  if (revealedKeys.value.has(keyId)) {
    revealedKeys.value.delete(keyId)
  } else {
    revealedKeys.value.add(keyId)
  }
}

async function handleCreateKey() {
  createKeyError.value = null
  creatingKey.value = true
  try {
    await apiKeysApi.createApiKey(auth.token!, project.value!.id, { name: newKeyName.value })
    showCreateKeyModal.value = false
    newKeyName.value = ''
    toast.add({ severity: 'success', summary: t('settings.apiKeys.createdToast'), life: 3000 })
    await reloadApiKeysFirstPage()
  } catch (e) {
    createKeyError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    creatingKey.value = false
  }
}

async function doRevokeKey(key: ApiKey) {
  await apiKeysApi.revokeApiKey(auth.token!, project.value!.id, key.id)
  toast.add({ severity: 'success', summary: t('settings.apiKeys.revokedToast'), life: 3000 })
  await loadApiKeys()
}

function handleRevokeKey(event: Event, key: ApiKey) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('settings.apiKeys.revokeConfirm'),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('settings.apiKeys.revoke'), severity: 'danger' },
    accept: () => doRevokeKey(key),
  })
}

async function doDeleteKey(key: ApiKey) {
  await apiKeysApi.deleteApiKey(auth.token!, project.value!.id, key.id)
  toast.add({ severity: 'success', summary: t('settings.apiKeys.deletedToast'), life: 3000 })
  await reloadApiKeysFirstPage()
}

function handleDeleteKey(event: Event, key: ApiKey) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('settings.apiKeys.deleteConfirm'),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: () => doDeleteKey(key),
  })
}

async function copyKey(key: string) {
  await navigator.clipboard.writeText(key)
  toast.add({ severity: 'success', summary: t('common.copiedToClipboard'), life: 2000 })
}
</script>

<template>
  <div class="flex max-w-2xl flex-col gap-6">
    <Message v-if="project && project.my_role !== 'admin'" severity="warn" :closable="false">
      {{ t('settings.notAdminHint') }}
    </Message>

    <Tabs v-else v-model:value="activeTab">
      <TabList>
        <Tab value="general">{{ t('settings.tabs.general') }}</Tab>
        <Tab value="llm">{{ t('settings.tabs.llm') }}</Tab>
        <Tab value="providers">{{ t('settings.tabs.providers') }}</Tab>
        <Tab value="apiKeys">{{ t('settings.tabs.apiKeys') }}</Tab>
        <Tab value="webhooks">{{ t('settings.tabs.webhooks') }}</Tab>
        <Tab value="members">{{ t('nav.members') }}</Tab>
      </TabList>
      <TabPanels>
    <TabPanel value="general">
    <Card>
      <template #title>{{ t('settings.project.cardTitle') }}</template>
      <template #content>
        <form class="flex flex-col gap-4" @submit.prevent="handleSave">
          <Message v-if="error" severity="error" :closable="false">{{ error }}</Message>

          <div class="flex flex-col gap-2">
            <label for="name" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.project.name')
            }}</label>
            <InputText id="name" v-model="name" fluid />
          </div>

          <Button type="submit" :label="t('settings.project.save')" :loading="saving" class="self-start" />
        </form>
      </template>
    </Card>
    </TabPanel>

    <TabPanel value="llm">
    <Card>
      <template #title>{{ t('settings.llm.cardTitle') }}</template>
      <template #content>
        <div v-if="llmConfigLoading || providerConfigsLoading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
        </div>

        <form v-else class="flex flex-col gap-4" @submit.prevent="handleSaveLlm">
          <Message v-if="llmError" severity="error" :closable="false">{{ llmError }}</Message>

          <div class="flex flex-col gap-2">
            <label for="active-config" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.llm.activeConfig')
            }}</label>
            <Select
              id="active-config"
              v-model="activeConfigId"
              :options="activeConfigOptions"
              option-label="label"
              option-value="value"
              :placeholder="t('settings.llm.activeConfigPlaceholder')"
              show-clear
              fluid
            />
            <p class="text-xs text-[var(--p-text-muted-color)]">
              {{ t('settings.llm.activeConfigHint') }}
            </p>
          </div>

          <div class="flex flex-col gap-2">
            <label for="cost-limit" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.llm.costLimit')
            }}</label>
            <InputNumber
              id="cost-limit"
              v-model="monthlyCostLimit"
              mode="currency"
              currency="USD"
              :min="0"
              :placeholder="t('settings.llm.noLimit')"
              fluid
            />
          </div>

          <div class="flex flex-col gap-2">
            <label for="token-limit" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.llm.tokenLimit')
            }}</label>
            <InputNumber
              id="token-limit"
              v-model="monthlyTokenLimit"
              :min="0"
              :placeholder="t('settings.llm.noLimit')"
              fluid
            />
          </div>

          <div class="flex flex-col gap-2">
            <label for="alert-email" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.llm.alertEmail')
            }}</label>
            <div class="flex items-center gap-2">
              <InputText
                id="alert-email"
                v-model="alertEmail"
                type="email"
                :placeholder="t('settings.llm.alertEmailPlaceholder')"
                fluid
              />
              <Button
                type="button"
                :label="t('settings.llm.testAlert')"
                text
                size="small"
                :loading="testingAlert"
                :disabled="!llmConfig?.alert_email"
                class="shrink-0"
                @click="handleTestAlert"
              />
            </div>
            <p v-if="!llmConfig?.alert_email" class="text-xs text-[var(--p-text-muted-color)]">
              {{ t('settings.llm.testAlertHint') }}
            </p>
          </div>

          <div class="flex flex-col gap-2">
            <label for="alert-threshold" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.llm.alertThreshold')
            }}</label>
            <InputNumber
              id="alert-threshold"
              v-model="alertThresholdPercent"
              :min="1"
              :max="100"
              suffix="%"
              :placeholder="t('settings.llm.noLimit')"
              fluid
            />
            <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('settings.llm.alertThresholdHint') }}</p>
          </div>

          <div class="flex flex-col gap-3 border-t border-[var(--p-content-border-color)] pt-4">
            <div class="flex items-center justify-between">
              <div class="flex flex-col gap-1">
                <label for="langfuse-enabled" class="text-sm font-medium text-[var(--p-text-color)]">{{
                  t('settings.llm.langfuseEnabled')
                }}</label>
                <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('settings.llm.langfuseHint') }}</p>
              </div>
              <ToggleSwitch id="langfuse-enabled" v-model="langfuseEnabled" />
            </div>

            <div v-if="langfuseEnabled" class="flex flex-col gap-2">
              <label for="langfuse-public-key" class="text-sm font-medium text-[var(--p-text-color)]">{{
                t('settings.llm.langfusePublicKey')
              }}</label>
              <InputText
                id="langfuse-public-key"
                v-model="langfusePublicKey"
                placeholder="pk-lf-..."
                fluid
              />
            </div>

            <div v-if="langfuseEnabled" class="flex flex-col gap-2">
              <label for="langfuse-secret-key" class="text-sm font-medium text-[var(--p-text-color)]">{{
                t('settings.llm.langfuseSecretKey')
              }}</label>
              <Password
                id="langfuse-secret-key"
                v-model="langfuseSecretKey"
                toggle-mask
                :feedback="false"
                fluid
                :placeholder="
                  llmConfig?.langfuse_secret_key_configured
                    ? t('settings.llm.langfuseSecretKeyConfigured')
                    : 'sk-lf-...'
                "
              />
            </div>
          </div>

          <Button type="submit" :label="t('settings.llm.save')" :loading="llmSaving" class="self-start" />
        </form>
      </template>
    </Card>
    </TabPanel>

    <TabPanel value="providers">
    <Card>
      <template #title>
        <div class="flex items-center justify-between">
          <span>{{ t('settings.llmProviders.cardTitle') }}</span>
          <Button :label="t('settings.llmProviders.newConfig')" icon="oi oi-plus" size="small" @click="openCreateModal" />
        </div>
      </template>
      <template #content>
        <p class="mb-4 text-sm text-[var(--p-text-muted-color)]">
          {{ t('settings.llmProviders.description') }}
        </p>

        <div v-if="providerConfigsLoading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
        </div>

        <EmptyState
          v-else-if="providerConfigs.length === 0"
          icon="oi oi-microchip"
          :message="t('settings.llmProviders.empty')"
          :action-label="t('settings.llmProviders.newConfig')"
          @action="openCreateModal"
        />

        <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
          <div
            v-for="config in providerConfigs"
            :key="config.id"
            class="flex flex-col gap-1 py-3 first:pt-0 last:pb-0"
          >
            <div class="flex min-w-0 items-center gap-2">
              <span class="w-28 shrink-0 truncate font-medium text-[var(--p-text-color)]">{{
                config.name
              }}</span>
              <div class="flex min-w-0 flex-1 items-center gap-2 overflow-hidden">
                <Tag
                  v-if="config.id === activeConfigId"
                  :value="t('settings.llmProviders.active')"
                  severity="success"
                  class="shrink-0"
                />
                <Tag :value="config.provider" severity="secondary" class="shrink-0" />
                <span v-if="config.model" class="truncate text-xs text-[var(--p-text-muted-color)]">{{
                  config.model
                }}</span>
                <Tag
                  v-if="!config.api_key_configured"
                  :value="t('settings.llmProviders.noKey')"
                  severity="warn"
                  class="shrink-0"
                />
              </div>
              <div class="ml-auto flex shrink-0 items-center gap-1">
                <Button
                  v-if="config.id !== activeConfigId"
                  :label="t('settings.llmProviders.setActive')"
                  text
                  size="small"
                  @click="setActiveConfig(config)"
                />
                <Button
                  icon="oi oi-pencil"
                  text
                  size="small"
                  severity="secondary"
                  @click="openEditModal(config)"
                />
                <Button
                  icon="oi oi-trash"
                  text
                  size="small"
                  severity="danger"
                  @click="(e) => handleDeleteConfig(e, config)"
                />
              </div>
            </div>
            <p v-if="config.description" class="truncate text-xs text-[var(--p-text-muted-color)]">
              {{ config.description }}
            </p>
          </div>
        </div>
      </template>
    </Card>
    </TabPanel>

    <TabPanel value="apiKeys">
    <Card>
      <template #title>
        <div class="flex items-center justify-between">
          <span>{{ t('settings.apiKeys.cardTitle') }}</span>
          <Button
            :label="t('settings.apiKeys.newKey')"
            icon="oi oi-plus"
            size="small"
            @click="showCreateKeyModal = true"
          />
        </div>
      </template>
      <template #content>
        <p class="mb-4 text-sm text-[var(--p-text-muted-color)]">
          {{ t('settings.apiKeys.description') }}
        </p>

        <div v-if="apiKeysLoading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
        </div>

        <EmptyState
          v-else-if="apiKeys.length === 0"
          icon="oi oi-key"
          :message="t('settings.apiKeys.empty')"
          :action-label="t('settings.apiKeys.newKey')"
          @action="showCreateKeyModal = true"
        />

        <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
          <div
            v-for="key in apiKeys"
            :key="key.id"
            class="flex min-w-0 items-center gap-3 py-3 first:pt-0 last:pb-0"
          >
            <span class="w-24 shrink-0 truncate font-medium text-[var(--p-text-color)]">{{
              key.name
            }}</span>
            <Tag
              :value="key.revoked_at ? t('settings.apiKeys.revoked') : t('settings.apiKeys.active')"
              :severity="key.revoked_at ? 'danger' : 'success'"
              class="shrink-0"
            />

            <div class="flex min-w-0 flex-1 items-center gap-2">
              <code v-if="key.key && revealedKeys.has(key.id)" class="min-w-0 truncate text-xs text-[var(--p-text-muted-color)]">{{
                key.key
              }}</code>
              <code v-else-if="key.key" class="text-xs text-[var(--p-text-muted-color)]"
                >••••••••••••••••</code
              >
              <span v-else class="text-xs italic text-[var(--p-text-muted-color)]">{{
                t('settings.apiKeys.notShown')
              }}</span>
              <Button
                v-if="key.key"
                :icon="revealedKeys.has(key.id) ? 'oi oi-eye-slash' : 'oi oi-eye'"
                text
                size="small"
                severity="secondary"
                class="shrink-0"
                @click="toggleReveal(key.id)"
              />
              <Button
                v-if="key.key"
                icon="oi oi-copy"
                text
                size="small"
                severity="secondary"
                class="shrink-0"
                @click="copyKey(key.key)"
              />
            </div>

            <span class="w-24 shrink-0 truncate text-right text-xs text-[var(--p-text-muted-color)]">
              {{ key.last_used_at ? formatDateTime(key.last_used_at) : t('settings.apiKeys.neverUsed') }}
            </span>

            <div class="flex shrink-0 items-center gap-1">
              <Button
                v-if="!key.revoked_at"
                :label="t('settings.apiKeys.revoke')"
                text
                severity="danger"
                size="small"
                @click="(e) => handleRevokeKey(e, key)"
              />
              <Button
                icon="oi oi-trash"
                text
                severity="danger"
                size="small"
                @click="(e) => handleDeleteKey(e, key)"
              />
            </div>
          </div>
        </div>

        <Paginator
          v-if="apiKeysTotal > API_KEYS_PAGE_SIZE"
          :rows="API_KEYS_PAGE_SIZE"
          :total-records="apiKeysTotal"
          :first="apiKeysFirst"
          class="mt-4"
          @page="onApiKeysPageChange"
        />
      </template>
    </Card>
    </TabPanel>

    <TabPanel value="webhooks">
      <ProjectWebhooksView />
    </TabPanel>

    <TabPanel value="members">
      <ProjectMembersView />
    </TabPanel>
      </TabPanels>
    </Tabs>

    <Dialog
      v-model:visible="showConfigModal"
      modal
      :header="editingConfig ? t('settings.llmProviders.modal.editHeader') : t('settings.llmProviders.modal.createHeader')"
      class="w-full max-w-md"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleSaveConfig">
        <Message v-if="configError" severity="error" :closable="false">{{ configError }}</Message>

        <div class="flex flex-col gap-2">
          <label for="config-name" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('settings.llmProviders.modal.name')
          }}</label>
          <InputText
            id="config-name"
            v-model="configName"
            :placeholder="t('settings.llmProviders.modal.namePlaceholder')"
            fluid
          />
        </div>

        <div class="flex flex-col gap-2">
          <label for="config-description" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('settings.llmProviders.modal.description')
          }}</label>
          <InputText
            id="config-description"
            v-model="configDescription"
            :placeholder="t('settings.llmProviders.modal.descriptionPlaceholder')"
            fluid
          />
        </div>

        <div class="flex flex-col gap-2">
          <label for="config-provider" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('settings.llmProviders.modal.provider')
          }}</label>
          <Select
            id="config-provider"
            v-model="configProvider"
            :options="providerOptions"
            option-label="label"
            option-value="value"
            fluid
          />
        </div>

        <Message v-if="configProvider === 'aws_translate'" severity="warn" :closable="false">
          {{ t('settings.llmProviders.modal.awsTranslateNote') }}
        </Message>

        <div class="flex flex-col gap-2">
          <label for="config-api-key" class="text-sm font-medium text-[var(--p-text-color)]">{{
            isAwsProvider ? t('settings.llmProviders.modal.accessKeyId') : t('settings.llmProviders.modal.apiKey')
          }}</label>
          <Password
            id="config-api-key"
            v-model="configApiKey"
            toggle-mask
            :feedback="false"
            fluid
            :placeholder="
              editingConfig?.api_key_configured
                ? t('settings.llmProviders.modal.apiKeyConfigured')
                : t('settings.llmProviders.modal.apiKeyPlaceholder')
            "
          />
        </div>

        <template v-if="isAwsProvider">
          <div class="flex flex-col gap-2">
            <label for="config-api-secret" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.llmProviders.modal.secretAccessKey')
            }}</label>
            <Password
              id="config-api-secret"
              v-model="configApiSecret"
              toggle-mask
              :feedback="false"
              fluid
              :placeholder="
                editingConfig?.api_secret_configured
                  ? t('settings.llmProviders.modal.apiKeyConfigured')
                  : t('settings.llmProviders.modal.apiKeyPlaceholder')
              "
            />
          </div>

          <div class="flex flex-col gap-2">
            <label for="config-region" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('settings.llmProviders.modal.region')
            }}</label>
            <InputText id="config-region" v-model="configRegion" placeholder="us-east-1" fluid />
          </div>
        </template>

        <div v-if="supportsModelSelection" class="flex flex-col gap-2">
          <label for="config-model" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('settings.llmProviders.modal.model')
          }}</label>
          <div class="flex items-center gap-2">
            <Select
              id="config-model"
              v-model="configModel"
              :options="availableModels"
              option-label="name"
              option-value="id"
              :placeholder="t('settings.llmProviders.modal.modelPlaceholder')"
              fluid
              :disabled="availableModels.length === 0"
            />
            <Button
              type="button"
              :label="t('settings.llmProviders.modal.fetchModels')"
              text
              size="small"
              :loading="modelsLoading"
              :disabled="!configApiKey || (isAwsProvider && (!configApiSecret || !configRegion))"
              class="shrink-0"
              @click="handleFetchModels"
            />
          </div>
          <Message v-if="modelsError" severity="error" :closable="false">{{ modelsError }}</Message>
          <p
            v-else-if="availableModels.length === 0 && configModel"
            class="text-xs text-[var(--p-text-muted-color)]"
          >
            {{ t('settings.llmProviders.modal.currentModelHint', { model: configModel }) }}
          </p>
        </div>

        <Button type="submit" :label="t('settings.llmProviders.modal.save')" :loading="configSaving" fluid />
      </form>
    </Dialog>

    <Dialog
      v-model:visible="showCreateKeyModal"
      modal
      :header="t('settings.apiKeys.createModal.header')"
      class="w-full max-w-sm"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleCreateKey">
        <Message v-if="createKeyError" severity="error" :closable="false">{{
          createKeyError
        }}</Message>
        <div class="flex flex-col gap-2">
          <label for="key-name" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('settings.apiKeys.createModal.name')
          }}</label>
          <InputText
            id="key-name"
            v-model="newKeyName"
            :placeholder="t('settings.apiKeys.createModal.namePlaceholder')"
            fluid
          />
        </div>
        <Button type="submit" :label="t('settings.apiKeys.createModal.submit')" :loading="creatingKey" fluid />
      </form>
    </Dialog>
  </div>
</template>
