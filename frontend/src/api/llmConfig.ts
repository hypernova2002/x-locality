import { apiRequest } from './client'
import type { LlmConfig } from './types'

export function getLlmConfig(token: string, projectId: string) {
  return apiRequest<LlmConfig>(`/api/v1/admin/projects/${projectId}/llm_config`, { token })
}

export function updateLlmConfig(
  token: string,
  projectId: string,
  params: Partial<{
    active_llm_provider_config_id: string | null
    monthly_cost_limit_usd: number | null
    monthly_token_limit: number | null
    alert_email: string | null
    alert_threshold_percent: number | null
    langfuse_enabled: boolean
    langfuse_public_key: string | null
    langfuse_secret_key: string
  }>,
) {
  return apiRequest<LlmConfig>(`/api/v1/admin/projects/${projectId}/llm_config`, {
    method: 'PATCH',
    body: params,
    token,
  })
}

export function testLlmAlert(token: string, projectId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/llm_config/test_alert`, {
    method: 'POST',
    token,
  })
}
