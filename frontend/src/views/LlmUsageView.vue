<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  LineElement,
  CategoryScale,
  LinearScale,
  PointElement,
} from 'chart.js'
import Select from 'openvue/select'
import Tag from 'openvue/tag'
import ProgressSpinner from 'openvue/progressspinner'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import * as usageApi from '@/api/usage'
import { formatDateTime } from '@/lib/formatDate'
import type { LlmUsageData } from '@/api/types'

ChartJS.register(Title, Tooltip, Legend, LineElement, CategoryScale, LinearScale, PointElement)

const route = useRoute()
const auth = useAuthStore()
const { t } = useI18n()
const { project } = useProject()

const projectId = computed(() => route.params.projectId as string | undefined)

const days = ref(30)
const dayOptions = computed(() => [
  { label: t('usage.last7Days'), value: 7 },
  { label: t('usage.last30Days'), value: 30 },
  { label: t('usage.last90Days'), value: 90 },
])

const data = ref<LlmUsageData | null>(null)
const loading = ref(true)

async function load() {
  loading.value = true
  const { data: usage } = await usageApi.getLlmUsage(auth.token!, projectId.value, days.value)
  data.value = usage
  loading.value = false
}

onMounted(load)
watch(days, load)
watch(projectId, load)

function formatCost(cost: number | null) {
  return cost === null ? '—' : `$${cost.toFixed(4)}`
}

function formatLatency(ms: number | null) {
  if (ms === null) return '—'
  return ms < 1000 ? `${ms}ms` : `${(ms / 1000).toFixed(1)}s`
}

const chartData = computed(() => ({
  labels: (data.value?.by_day ?? []).map((d) => d.date),
  datasets: [
    {
      label: t('usage.llm.inputTokens'),
      data: (data.value?.by_day ?? []).map((d) => d.input_tokens),
      borderColor: '#5b8def',
      backgroundColor: 'rgba(91, 141, 239, 0.15)',
      tension: 0.3,
      fill: true,
    },
    {
      label: t('usage.llm.outputTokens'),
      data: (data.value?.by_day ?? []).map((d) => d.output_tokens),
      borderColor: '#8b7fd1',
      backgroundColor: 'rgba(139, 127, 209, 0.15)',
      tension: 0.3,
      fill: true,
    },
  ],
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: true, position: 'bottom' as const } },
  scales: { y: { beginAtZero: true, ticks: { precision: 0 } } },
}
</script>

<template>
  <div>
    <div class="mb-4 flex items-center justify-between">
      <p class="text-sm text-[var(--p-text-muted-color)]">
        {{ project ? project.name : t('usage.allProjects') }}
      </p>
      <Select
        v-model="days"
        :options="dayOptions"
        option-label="label"
        option-value="value"
        style="width: 10rem"
      />
    </div>

    <div v-if="loading" class="flex justify-center py-12">
      <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
    </div>

    <template v-else-if="data">
      <div class="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.llm.inputTokens') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">
            {{ data.total_input_tokens.toLocaleString() }}
          </p>
        </div>
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.llm.outputTokens') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">
            {{ data.total_output_tokens.toLocaleString() }}
          </p>
        </div>
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.llm.estimatedCost') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">{{ formatCost(data.total_cost) }}</p>
        </div>
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.llm.avgLatency') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">
            {{ formatLatency(data.avg_latency_ms) }}
          </p>
        </div>
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.llm.calls') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">
            {{ data.successful_calls + data.failed_calls }}
          </p>
          <p class="mt-1 text-xs text-[var(--p-text-muted-color)]">
            <span class="text-green-600">{{
              t('usage.llm.succeeded', { count: data.successful_calls })
            }}</span>
            ·
            <span class="text-red-600">{{ t('usage.llm.failed', { count: data.failed_calls }) }}</span>
          </p>
        </div>
      </div>

      <div
        class="mb-6 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4"
        style="height: 320px"
      >
        <Line v-if="data.by_day.length > 0" :data="chartData" :options="chartOptions" />
        <p v-else class="flex h-full items-center justify-center text-sm text-[var(--p-text-muted-color)]">
          {{ t('usage.llm.noUsage') }}
        </p>
      </div>

      <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
        <h2 class="mb-3 text-sm font-medium text-[var(--p-text-color)]">{{ t('usage.llm.byProviderModel') }}</h2>
        <p v-if="data.by_provider_model.length === 0" class="text-sm text-[var(--p-text-muted-color)]">
          {{ t('usage.llm.noUsage') }}
        </p>
        <div v-else class="overflow-x-auto">
          <div class="flex min-w-[46rem] items-center gap-3 border-b border-[var(--p-content-border-color)] pb-2 text-xs font-medium text-[var(--p-text-muted-color)]">
            <span class="w-24 shrink-0">{{ t('usage.llm.colProvider') }}</span>
            <span class="w-36 shrink-0 truncate">{{ t('usage.llm.colModel') }}</span>
            <span class="w-16 shrink-0 text-right">{{ t('usage.llm.colTranslations') }}</span>
            <span class="w-20 shrink-0 text-right">{{ t('usage.llm.colCalls') }}</span>
            <span class="w-16 shrink-0 text-right">{{ t('usage.llm.colInput') }}</span>
            <span class="w-16 shrink-0 text-right">{{ t('usage.llm.colOutput') }}</span>
            <span class="w-16 shrink-0 text-right">{{ t('usage.llm.colLatency') }}</span>
            <span class="ml-auto w-16 shrink-0 text-right">{{ t('usage.llm.colCost') }}</span>
          </div>
          <div class="flex min-w-[46rem] flex-col divide-y divide-[var(--p-content-border-color)]">
            <div
              v-for="row in data.by_provider_model"
              :key="`${row.provider}-${row.model}`"
              class="flex items-center gap-3 py-2.5"
            >
              <Tag :value="row.provider" severity="secondary" class="w-24 shrink-0" />
              <span class="w-36 shrink-0 truncate text-sm text-[var(--p-text-color)]">{{ row.model }}</span>
              <span class="w-16 shrink-0 text-right text-sm text-[var(--p-text-color)]">{{
                row.translation_count
              }}</span>
              <span class="w-20 shrink-0 text-right text-sm text-[var(--p-text-color)]">
                <span class="text-green-600">{{ row.successful_calls }}</span>
                /
                <span :class="row.failed_calls > 0 ? 'text-red-600' : ''">{{ row.failed_calls }}</span>
              </span>
              <span class="w-16 shrink-0 text-right text-sm text-[var(--p-text-color)]">
                {{ row.input_tokens.toLocaleString() }}
              </span>
              <span class="w-16 shrink-0 text-right text-sm text-[var(--p-text-color)]">
                {{ row.output_tokens.toLocaleString() }}
              </span>
              <span class="w-16 shrink-0 text-right text-sm text-[var(--p-text-color)]">
                {{ formatLatency(row.avg_latency_ms) }}
              </span>
              <span class="ml-auto w-16 shrink-0 text-right text-sm text-[var(--p-text-color)]">
                {{ formatCost(row.cost) }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="data.recent_failures.length > 0"
        class="mt-6 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4"
      >
        <h2 class="mb-3 text-sm font-medium text-[var(--p-text-color)]">{{ t('usage.llm.recentFailures') }}</h2>
        <div class="flex flex-col gap-2">
          <div
            v-for="(failure, i) in data.recent_failures"
            :key="i"
            class="rounded border border-[var(--p-content-border-color)] p-3"
          >
            <div class="mb-1 flex items-center gap-2 text-xs text-[var(--p-text-muted-color)]">
              <Tag :value="failure.provider" severity="secondary" />
              <span>{{ failure.model }}</span>
              <span>·</span>
              <span>{{ formatDateTime(failure.created_at) }}</span>
            </div>
            <p class="text-sm text-red-600">{{ failure.error_message ?? t('usage.llm.noErrorMessage') }}</p>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
