<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
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
import ProgressSpinner from 'openvue/progressspinner'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import * as usageApi from '@/api/usage'
import type { TranslationUsageData } from '@/api/types'

ChartJS.register(Title, Tooltip, Legend, LineElement, CategoryScale, LinearScale, PointElement)

const auth = useAuthStore()
const { t } = useI18n()
const { project } = useProject()

const days = ref(30)
const dayOptions = computed(() => [
  { label: t('usage.last7Days'), value: 7 },
  { label: t('usage.last30Days'), value: 30 },
  { label: t('usage.last90Days'), value: 90 },
])

const data = ref<TranslationUsageData | null>(null)
const loading = ref(true)

async function load() {
  if (!project.value) return
  loading.value = true
  const { data: usage } = await usageApi.getTranslationUsage(auth.token!, project.value.id, days.value)
  data.value = usage
  loading.value = false
}

onMounted(load)
watch(days, load)
watch(project, load)

const chartData = computed(() => ({
  labels: (data.value?.by_day ?? []).map((d) => d.date),
  datasets: [
    {
      label: t('usage.translations.cacheHits'),
      data: (data.value?.by_day ?? []).map((d) => d.cache_hits),
      borderColor: '#5b8def',
      backgroundColor: 'rgba(91, 141, 239, 0.15)',
      tension: 0.3,
      fill: true,
    },
    {
      label: t('usage.translations.llmGenerations'),
      data: (data.value?.by_day ?? []).map((d) => d.llm_generations),
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
      <p class="text-sm text-[var(--p-text-muted-color)]">{{ project?.name }}</p>
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
      <div class="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.translations.totalRequests') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">
            {{ data.total_requests.toLocaleString() }}
          </p>
        </div>
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.translations.cacheHits') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">
            {{ data.cache_hits.toLocaleString() }}
          </p>
        </div>
        <div class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4">
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('usage.translations.llmGenerations') }}</p>
          <p class="text-2xl font-semibold text-[var(--p-text-color)]">
            {{ data.llm_generations.toLocaleString() }}
          </p>
        </div>
      </div>

      <div
        class="rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4"
        style="height: 320px"
      >
        <Line v-if="data.by_day.length > 0" :data="chartData" :options="chartOptions" />
        <p v-else class="flex h-full items-center justify-center text-sm text-[var(--p-text-muted-color)]">
          {{ t('usage.translations.noUsage') }}
        </p>
      </div>
    </template>
  </div>
</template>
