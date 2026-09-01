import { apiRequest, apiRequestBlob } from './client'
import type { Locale } from './types'

export interface LocalesPage {
  locales: Locale[]
  total: number
}

export interface LocalesPageParams {
  offset?: number
  limit?: number
  [key: string]: string | number | undefined
}

export async function listLocales(
  token: string,
  projectId: string,
  params: LocalesPageParams = {},
): Promise<LocalesPage> {
  const { data, totalCount } = await apiRequest<Locale[]>(
    `/api/v1/admin/projects/${projectId}/locales`,
    { token, query: params },
  )
  return { locales: data, total: totalCount ?? data.length }
}

export function createLocale(
  token: string,
  projectId: string,
  params: {
    key: string
    target_language: string
    style_tone_text?: string
    general_description?: string
  },
) {
  return apiRequest<Locale>(`/api/v1/admin/projects/${projectId}/locales`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function updateLocale(
  token: string,
  projectId: string,
  localeId: string,
  params: Partial<{
    style_tone_text: string
    general_description: string
    target_language: string
  }>,
) {
  return apiRequest<Locale>(`/api/v1/admin/projects/${projectId}/locales/${localeId}`, {
    method: 'PATCH',
    body: params,
    token,
  })
}

export function deleteLocale(token: string, projectId: string, localeId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/locales/${localeId}`, {
    method: 'DELETE',
    token,
  })
}

export function exportLocales(token: string, projectId: string, format: 'csv' | 'json') {
  return apiRequestBlob(`/api/v1/admin/projects/${projectId}/locales/export`, {
    token,
    query: { format },
  })
}

export interface LocaleImportSkippedRow {
  key: string
  reason: string
}

export interface LocaleImportSummary {
  created: number
  updated: number
  skipped: LocaleImportSkippedRow[]
}

export function importLocales(
  token: string,
  projectId: string,
  params: { format: 'csv' | 'json'; content_base64: string; compressed: boolean },
) {
  return apiRequest<LocaleImportSummary>(`/api/v1/admin/projects/${projectId}/locales/import`, {
    method: 'POST',
    body: params,
    token,
  })
}

export interface BulkTranslateCandidate {
  key: string
  source_text: string
  source_language: string | null
  context: string[]
}

export interface BulkTranslateCandidates {
  candidates: BulkTranslateCandidate[]
  total: number
}

export function getBulkTranslateCandidates(token: string, projectId: string, localeId: string) {
  return apiRequest<BulkTranslateCandidates>(
    `/api/v1/admin/projects/${projectId}/locales/${localeId}/bulk_translate_candidates`,
    { token },
  )
}

export interface BulkTranslateResultItem {
  key: string
  translations: { locale: string; status: 'pending' | 'completed' | 'failed' }[]
}

export function bulkTranslateLocale(token: string, projectId: string, localeId: string, keys: string[]) {
  return apiRequest<BulkTranslateResultItem[]>(
    `/api/v1/admin/projects/${projectId}/locales/${localeId}/bulk_translate`,
    { method: 'POST', body: { keys }, token },
  )
}
