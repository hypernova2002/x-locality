import { apiRequest } from './client'
import type { LlmModelOption, LlmProviderConfig } from './types'

export function listLlmProviderConfigs(token: string, projectId: string) {
  return apiRequest<LlmProviderConfig[]>(`/api/v1/admin/projects/${projectId}/llm_provider_configs`, {
    token,
  })
}

export function createLlmProviderConfig(
  token: string,
  projectId: string,
  params: {
    name: string
    provider: string
    description?: string
    model?: string
    api_key?: string
    api_secret?: string
    region?: string
  },
) {
  return apiRequest<LlmProviderConfig>(`/api/v1/admin/projects/${projectId}/llm_provider_configs`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function updateLlmProviderConfig(
  token: string,
  projectId: string,
  configId: string,
  params: Partial<{
    name: string
    description: string | null
    provider: string
    model: string | null
    api_key: string | null
    api_secret: string | null
    region: string | null
  }>,
) {
  return apiRequest<LlmProviderConfig>(
    `/api/v1/admin/projects/${projectId}/llm_provider_configs/${configId}`,
    { method: 'PATCH', body: params, token },
  )
}

export function deleteLlmProviderConfig(token: string, projectId: string, configId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/llm_provider_configs/${configId}`, {
    method: 'DELETE',
    token,
  })
}

export function listModelsFor(
  token: string,
  projectId: string,
  params: { provider: string; api_key: string; api_secret?: string; region?: string },
) {
  return apiRequest<LlmModelOption[]>(
    `/api/v1/admin/projects/${projectId}/llm_provider_configs/models`,
    { method: 'POST', body: params, token },
  )
}
