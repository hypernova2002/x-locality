import { apiRequest, apiRequestBlob } from './client'
import type { ContextTag } from './types'

export interface ContextTagsPage {
  tags: ContextTag[]
  total: number
}

export interface ContextTagsPageParams {
  offset?: number
  limit?: number
  [key: string]: string | number | undefined
}

export async function listContextTags(
  token: string,
  projectId: string,
  params: ContextTagsPageParams = {},
): Promise<ContextTagsPage> {
  const { data, totalCount } = await apiRequest<ContextTag[]>(
    `/api/v1/admin/projects/${projectId}/context_tags`,
    { token, query: params },
  )
  return { tags: data, total: totalCount ?? data.length }
}

export function createContextTag(
  token: string,
  projectId: string,
  params: { key: string; description?: string },
) {
  return apiRequest<ContextTag>(`/api/v1/admin/projects/${projectId}/context_tags`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function updateContextTag(
  token: string,
  projectId: string,
  tagId: string,
  params: Partial<{ key: string; description: string }>,
) {
  return apiRequest<ContextTag>(`/api/v1/admin/projects/${projectId}/context_tags/${tagId}`, {
    method: 'PATCH',
    body: params,
    token,
  })
}

export function deleteContextTag(token: string, projectId: string, tagId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/context_tags/${tagId}`, {
    method: 'DELETE',
    token,
  })
}

export function exportContextTags(token: string, projectId: string, format: 'csv' | 'json') {
  return apiRequestBlob(`/api/v1/admin/projects/${projectId}/context_tags/export`, {
    token,
    query: { format },
  })
}

export interface ContextTagImportSkippedRow {
  key: string
  reason: string
}

export interface ContextTagImportSummary {
  created: number
  updated: number
  skipped: ContextTagImportSkippedRow[]
}

export function importContextTags(
  token: string,
  projectId: string,
  params: { format: 'csv' | 'json'; content_base64: string; compressed: boolean },
) {
  return apiRequest<ContextTagImportSummary>(`/api/v1/admin/projects/${projectId}/context_tags/import`, {
    method: 'POST',
    body: params,
    token,
  })
}
