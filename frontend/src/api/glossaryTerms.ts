import { apiRequest, apiRequestBlob } from './client'
import type { GlossaryTerm } from './types'

export interface GlossaryTermsPage {
  terms: GlossaryTerm[]
  total: number
}

export interface GlossaryTermsPageParams {
  offset?: number
  limit?: number
  [key: string]: string | number | undefined
}

export async function listGlossaryTerms(
  token: string,
  projectId: string,
  params: GlossaryTermsPageParams = {},
): Promise<GlossaryTermsPage> {
  const { data, totalCount } = await apiRequest<GlossaryTerm[]>(
    `/api/v1/admin/projects/${projectId}/glossary_terms`,
    { token, query: params },
  )
  return { terms: data, total: totalCount ?? data.length }
}

export function createGlossaryTerm(
  token: string,
  projectId: string,
  params: {
    source_term: string
    source_language: string
    target_term: string
    target_locale_key?: string
  },
) {
  return apiRequest<GlossaryTerm>(`/api/v1/admin/projects/${projectId}/glossary_terms`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function updateGlossaryTerm(
  token: string,
  projectId: string,
  termId: string,
  params: Partial<{
    source_term: string
    source_language: string
    target_term: string
    target_locale_key: string | null
  }>,
) {
  return apiRequest<GlossaryTerm>(`/api/v1/admin/projects/${projectId}/glossary_terms/${termId}`, {
    method: 'PATCH',
    body: params,
    token,
  })
}

export function deleteGlossaryTerm(token: string, projectId: string, termId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/glossary_terms/${termId}`, {
    method: 'DELETE',
    token,
  })
}

export function exportGlossaryTerms(token: string, projectId: string, format: 'csv' | 'json') {
  return apiRequestBlob(`/api/v1/admin/projects/${projectId}/glossary_terms/export`, {
    token,
    query: { format },
  })
}

export interface GlossaryTermImportSkippedRow {
  key: string
  reason: string
}

export interface GlossaryTermImportSummary {
  created: number
  updated: number
  skipped: GlossaryTermImportSkippedRow[]
}

export function importGlossaryTerms(
  token: string,
  projectId: string,
  params: { format: 'csv' | 'json'; content_base64: string; compressed: boolean },
) {
  return apiRequest<GlossaryTermImportSummary>(`/api/v1/admin/projects/${projectId}/glossary_terms/import`, {
    method: 'POST',
    body: params,
    token,
  })
}
