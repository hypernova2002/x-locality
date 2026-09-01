import { apiRequest } from './client'
import type { ApiKey } from './types'

export interface ApiKeysPage {
  keys: ApiKey[]
  total: number
}

export interface ApiKeysPageParams {
  offset?: number
  limit?: number
  [key: string]: string | number | undefined
}

export async function listApiKeys(
  token: string,
  projectId: string,
  params: ApiKeysPageParams = {},
): Promise<ApiKeysPage> {
  const { data, totalCount } = await apiRequest<ApiKey[]>(
    `/api/v1/admin/projects/${projectId}/api_keys`,
    { token, query: params },
  )
  return { keys: data, total: totalCount ?? data.length }
}

export function createApiKey(token: string, projectId: string, params: { name: string }) {
  return apiRequest<ApiKey>(`/api/v1/admin/projects/${projectId}/api_keys`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function revokeApiKey(token: string, projectId: string, apiKeyId: string) {
  return apiRequest<ApiKey>(`/api/v1/admin/projects/${projectId}/api_keys/${apiKeyId}/revoke`, {
    method: 'POST',
    token,
  })
}

export function deleteApiKey(token: string, projectId: string, apiKeyId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/api_keys/${apiKeyId}`, {
    method: 'DELETE',
    token,
  })
}
