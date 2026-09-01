import { apiRequest, apiRequestBlob } from './client'
import type { Translation, TranslationGroup, TranslationGroupDetail, TranslationVersion } from './types'

export interface TranslationGroupsPage {
  groups: TranslationGroup[]
  total: number
}

export interface TranslationGroupFilters {
  search?: string
  key?: string
  status?: string
  source_language?: string
  target_language?: string
  llm_provider?: string
  llm_model?: string
  locked?: string
  offset?: number
  limit?: number
  [key: string]: string | number | undefined
}

export async function listTranslationGroups(
  token: string,
  projectId: string,
  params: TranslationGroupFilters = {},
): Promise<TranslationGroupsPage> {
  const { data, totalCount } = await apiRequest<TranslationGroup[]>(
    `/api/v1/admin/projects/${projectId}/translations`,
    { token, query: params },
  )

  return { groups: data, total: totalCount ?? data.length }
}

export function getTranslationsByKey(token: string, projectId: string, key: string) {
  return apiRequest<TranslationGroupDetail>(
    `/api/v1/admin/projects/${projectId}/translations/by_key/${encodeURIComponent(key)}`,
    { token },
  )
}

export function updateTranslation(
  token: string,
  projectId: string,
  translationId: string,
  params: { translated_text: string },
) {
  return apiRequest<Translation>(
    `/api/v1/admin/projects/${projectId}/translations/${translationId}`,
    {
      method: 'PATCH',
      body: params,
      token,
    },
  )
}

export function listTranslationVersions(token: string, projectId: string, translationId: string) {
  return apiRequest<TranslationVersion[]>(
    `/api/v1/admin/projects/${projectId}/translations/${translationId}/versions`,
    { token },
  )
}

export function regenerateTranslation(token: string, projectId: string, translationId: string) {
  return apiRequest<Translation>(
    `/api/v1/admin/projects/${projectId}/translations/${translationId}/regenerate`,
    { method: 'POST', token },
  )
}

export function lockTranslationKey(token: string, projectId: string, key: string) {
  return apiRequest<{ key: string; locked: boolean }>(
    `/api/v1/admin/projects/${projectId}/translations/by_key/${encodeURIComponent(key)}/lock`,
    { method: 'POST', token },
  )
}

export function unlockTranslationKey(token: string, projectId: string, key: string) {
  return apiRequest<{ key: string; locked: boolean }>(
    `/api/v1/admin/projects/${projectId}/translations/by_key/${encodeURIComponent(key)}/unlock`,
    { method: 'POST', token },
  )
}

export function addTranslationLocale(token: string, projectId: string, key: string, locale: string) {
  return apiRequest<Translation>(
    `/api/v1/admin/projects/${projectId}/translations/by_key/${encodeURIComponent(key)}/locales`,
    { method: 'POST', body: { locale }, token },
  )
}

export function bulkDeleteTranslations(token: string, projectId: string, keys: string[]) {
  return apiRequest<{ deleted: string[]; skipped: { key: string; reason: string }[] }>(
    `/api/v1/admin/projects/${projectId}/translations/bulk_delete`,
    { method: 'POST', body: { keys }, token },
  )
}

export function bulkRegenerateTranslations(token: string, projectId: string, keys: string[]) {
  return apiRequest<{ regenerated: string[]; failed: { key: string; reason: string }[] }>(
    `/api/v1/admin/projects/${projectId}/translations/bulk_regenerate`,
    { method: 'POST', body: { keys }, token },
  )
}

export function exportTranslations(token: string, projectId: string, format: 'csv' | 'json') {
  return apiRequestBlob(`/api/v1/admin/projects/${projectId}/translations/export`, {
    token,
    query: { format },
  })
}

export interface ImportSkippedRow {
  key: string
  locale: string
  reason: string
}

export interface ImportSummary {
  created: number
  updated: number
  skipped: ImportSkippedRow[]
}

export function importTranslations(
  token: string,
  projectId: string,
  params: { format: 'csv' | 'json'; content_base64: string; compressed: boolean },
) {
  return apiRequest<ImportSummary>(`/api/v1/admin/projects/${projectId}/translations/import`, {
    method: 'POST',
    body: params,
    token,
  })
}
