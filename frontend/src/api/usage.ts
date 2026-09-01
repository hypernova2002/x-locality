import { apiRequest } from './client'
import type { ApiUsageData, LlmUsageData, TranslationUsageData } from './types'

export function getApiUsage(token: string, projectId?: string, days = 30) {
  const path = projectId
    ? `/api/v1/admin/projects/${projectId}/usage/requests`
    : '/api/v1/admin/usage/requests'
  return apiRequest<ApiUsageData>(path, { token, query: { days } })
}

export function getLlmUsage(token: string, projectId?: string, days = 30) {
  const path = projectId ? `/api/v1/admin/projects/${projectId}/usage/llm` : '/api/v1/admin/usage/llm'
  return apiRequest<LlmUsageData>(path, { token, query: { days } })
}

// Project-scoped only - a translation usage event only makes sense within
// the project it belongs to. Omit `days` for an all-time total.
export function getTranslationUsage(token: string, projectId: string, days?: number) {
  return apiRequest<TranslationUsageData>(`/api/v1/admin/projects/${projectId}/usage/translations`, {
    token,
    query: { days },
  })
}
