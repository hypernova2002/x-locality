<script setup lang="ts">
import { ref, computed, reactive, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import Card from 'openvue/card'
import Textarea from 'openvue/textarea'
import Button from 'openvue/button'
import Tag from 'openvue/tag'
import Select from 'openvue/select'
import Message from 'openvue/message'
import Timeline from 'openvue/timeline'
import ProgressSpinner from 'openvue/progressspinner'
import { useToast } from 'openvue/usetoast'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import * as translationsApi from '@/api/translations'
import * as localesApi from '@/api/locales'
import { ApiError } from '@/api/client'
import { formatDateTime } from '@/lib/formatDate'
import type { Translation, TranslationGroupDetail, TranslationVersion } from '@/api/types'

const props = defineProps<{ translationKey: string }>()

const auth = useAuthStore()
const toast = useToast()
const { t } = useI18n()
const { project } = useProject()

const group = ref<TranslationGroupDetail | null>(null)
const loading = ref(true)
const loadError = ref<string | null>(null)

interface LocaleState {
  editedText: string
  error: string | null
  saving: boolean
  regenerating: boolean
  historyOpen: boolean
  historyLoading: boolean
  versions: TranslationVersion[]
}

const localeState = reactive<Record<string, LocaleState>>({})

function stateFor(translation: Translation): LocaleState {
  if (!localeState[translation.id]) {
    localeState[translation.id] = {
      editedText: translation.translated_text ?? '',
      error: null,
      saving: false,
      regenerating: false,
      historyOpen: false,
      historyLoading: false,
      versions: [],
    }
  }
  return localeState[translation.id]!
}

async function load() {
  loading.value = true
  loadError.value = null
  try {
    const { data } = await translationsApi.getTranslationsByKey(
      auth.token!,
      project.value!.id,
      props.translationKey,
    )
    group.value = data
    data.translations.forEach(stateFor)
  } catch (e) {
    group.value = null
    loadError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    loading.value = false
  }
}

// --- add locale ---
const allLocales = ref<{ key: string }[]>([])
const selectedNewLocale = ref<string | null>(null)
const addingLocale = ref(false)
const addLocaleError = ref<string | null>(null)

async function loadAllLocales() {
  const { locales } = await localesApi.listLocales(auth.token!, project.value!.id, { limit: 100 })
  allLocales.value = locales
}

const availableLocaleOptions = computed(() => {
  const present = new Set((group.value?.translations ?? []).map((tr) => tr.locale))
  return allLocales.value.filter((l) => !present.has(l.key)).map((l) => ({ label: l.key, value: l.key }))
})

async function handleAddLocale() {
  if (!selectedNewLocale.value || !group.value) return
  addLocaleError.value = null
  addingLocale.value = true
  try {
    const { data: created } = await translationsApi.addTranslationLocale(
      auth.token!,
      project.value!.id,
      group.value.key,
      selectedNewLocale.value,
    )
    group.value.translations.push(created)
    stateFor(created)
    selectedNewLocale.value = null
    toast.add({ severity: 'success', summary: t('translationDetail.localeAddedToast'), life: 3000 })
  } catch (e) {
    addLocaleError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    addingLocale.value = false
  }
}

onMounted(() => {
  load()
  loadAllLocales()
})
watch(() => props.translationKey, load)

// stateFor() only seeds editedText the first time it sees a translation id,
// so applying a fresh server response through it wouldn't stick - update
// the group + editedText directly from the response instead of re-fetching
// and hoping the cache picks it up.
function applyUpdatedTranslation(updated: Translation) {
  if (!group.value) return
  const idx = group.value.translations.findIndex((tr) => tr.id === updated.id)
  if (idx !== -1) group.value.translations[idx] = updated
  stateFor(updated).editedText = updated.translated_text ?? ''
}

async function handleSave(translation: Translation) {
  const state = stateFor(translation)
  state.error = null
  state.saving = true
  try {
    const { data: updated } = await translationsApi.updateTranslation(
      auth.token!,
      project.value!.id,
      translation.id,
      { translated_text: state.editedText },
    )
    applyUpdatedTranslation(updated)
    toast.add({ severity: 'success', summary: t('translationDetail.updatedToast'), life: 3000 })
    if (state.historyOpen) await loadHistory(updated)
  } catch (e) {
    state.error = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    state.saving = false
  }
}

async function handleRegenerate(translation: Translation) {
  const state = stateFor(translation)
  state.error = null
  state.regenerating = true
  try {
    const { data: updated } = await translationsApi.regenerateTranslation(
      auth.token!,
      project.value!.id,
      translation.id,
    )
    applyUpdatedTranslation(updated)
    toast.add({ severity: 'success', summary: t('translationDetail.regeneratedToast'), life: 3000 })
    if (state.historyOpen) await loadHistory(updated)
  } catch (e) {
    state.error = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    state.regenerating = false
  }
}

async function toggleLock() {
  if (!group.value) return
  if (group.value.locked) {
    await translationsApi.unlockTranslationKey(auth.token!, project.value!.id, group.value.key)
    group.value.locked = false
    toast.add({ severity: 'success', summary: t('translations.unlockedToast'), life: 2000 })
  } else {
    await translationsApi.lockTranslationKey(auth.token!, project.value!.id, group.value.key)
    group.value.locked = true
    toast.add({ severity: 'success', summary: t('translations.lockedToast'), life: 2000 })
  }
}

async function loadHistory(translation: Translation) {
  const state = stateFor(translation)
  state.historyLoading = true
  const { data } = await translationsApi.listTranslationVersions(
    auth.token!,
    project.value!.id,
    translation.id,
  )
  state.versions = data
  state.historyLoading = false
}

async function toggleHistory(translation: Translation) {
  const state = stateFor(translation)
  state.historyOpen = !state.historyOpen
  if (state.historyOpen && state.versions.length === 0) await loadHistory(translation)
}

const statusSeverity: Record<Translation['status'], 'success' | 'danger' | 'warn'> = {
  completed: 'success',
  failed: 'danger',
  pending: 'warn',
}
</script>

<template>
  <div>
    <div v-if="loading" class="flex justify-center py-12">
      <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
    </div>

    <Message v-else-if="loadError" severity="error" :closable="false">{{ loadError }}</Message>

    <template v-else-if="group">
      <p class="mb-1 text-xs font-medium text-[var(--p-text-muted-color)]">{{ t('translationDetail.label') }}</p>

      <div class="mb-4">
        <div class="flex items-center justify-between">
          <code class="text-lg font-medium text-[var(--p-text-color)]">{{ group.key }}</code>
          <Button
            :label="group.locked ? t('translationDetail.unlock') : t('translationDetail.lock')"
            :icon="group.locked ? 'oi oi-lock' : 'oi oi-unlock'"
            text
            size="small"
            severity="secondary"
            @click="toggleLock"
          />
        </div>
        <p class="mt-1 rounded border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-3 text-sm">
          {{ group.source_text }}
        </p>
      </div>

      <div v-if="availableLocaleOptions.length > 0" class="mb-4 flex items-start gap-2">
        <Select
          v-model="selectedNewLocale"
          :options="availableLocaleOptions"
          option-label="label"
          option-value="value"
          :placeholder="t('translationDetail.addLocalePlaceholder')"
          style="width: 12rem"
        />
        <Button
          :label="t('translationDetail.addLocale')"
          icon="oi oi-plus"
          size="small"
          :disabled="!selectedNewLocale"
          :loading="addingLocale"
          @click="handleAddLocale"
        />
        <Message v-if="addLocaleError" severity="error" :closable="false" class="flex-1">{{
          addLocaleError
        }}</Message>
      </div>

      <div class="flex flex-col gap-4">
        <Card v-for="translation in group.translations" :key="translation.id">
          <template #title>
            <div class="flex flex-wrap items-center gap-2 text-base">
              <span>{{ translation.locale }}</span>
              <Tag :value="translation.status" :severity="statusSeverity[translation.status]" />
              <Tag :value="translation.generated_by" severity="secondary" />
              <span v-if="translation.model_used" class="text-xs font-normal text-[var(--p-text-muted-color)]">
                {{ translation.model_used }}
              </span>
              <span
                v-if="translation.usage && translation.usage.total_requests > 0"
                class="flex items-center gap-1 text-xs font-normal text-[var(--p-text-muted-color)]"
                :title="
                  t('translations.usageTooltip', {
                    cached: translation.usage.cache_hits,
                    generated: translation.usage.llm_generations,
                  })
                "
              >
                <i class="oi oi-chart-line" />
                {{ t('translationDetail.usageCount', { count: translation.usage.total_requests }) }}
              </span>
            </div>
          </template>
          <template #content>
            <Message v-if="stateFor(translation).error" severity="error" :closable="false" class="mb-3">
              {{ stateFor(translation).error }}
            </Message>

            <Textarea
              v-model="stateFor(translation).editedText"
              rows="3"
              fluid
              class="mb-3"
            />

            <div class="flex items-center gap-2">
              <Button
                :label="t('translationDetail.save')"
                size="small"
                :loading="stateFor(translation).saving"
                @click="handleSave(translation)"
              />
              <Button
                :label="t('translationDetail.regenerate')"
                icon="oi oi-refresh"
                text
                size="small"
                severity="secondary"
                :loading="stateFor(translation).regenerating"
                @click="handleRegenerate(translation)"
              />
              <Button
                :label="
                  stateFor(translation).historyOpen
                    ? t('translationDetail.hideHistory')
                    : t('translationDetail.showHistory')
                "
                text
                size="small"
                severity="secondary"
                @click="toggleHistory(translation)"
              />
            </div>

            <div v-if="stateFor(translation).historyOpen" class="mt-4">
              <div v-if="stateFor(translation).historyLoading" class="flex justify-center py-4">
                <ProgressSpinner style="width: 1.75rem; height: 1.75rem" stroke-width="4" />
              </div>
              <p
                v-else-if="stateFor(translation).versions.length === 0"
                class="text-sm text-[var(--p-text-muted-color)]"
              >
                {{ t('translationDetail.noEdits') }}
              </p>
              <Timeline v-else :value="stateFor(translation).versions">
                <template #content="{ item }">
                  <p class="text-xs text-[var(--p-text-muted-color)]">
                    {{
                      item.changed_by_type === 'user'
                        ? item.changed_by_user_email
                        : t('translationDetail.llmGeneration')
                    }}
                    · {{ formatDateTime(item.created_at) }}
                  </p>
                  <p v-if="item.previous_value" class="text-sm text-[var(--p-text-muted-color)] line-through">
                    {{ item.previous_value }}
                  </p>
                  <p class="text-sm text-[var(--p-text-color)]">{{ item.new_value }}</p>
                </template>
              </Timeline>
            </div>
          </template>
        </Card>
      </div>
    </template>
  </div>
</template>
