import type { ProblemDetails } from './types'

const BASE_URL = import.meta.env.VITE_API_BASE_URL

export class ApiError extends Error {
  status: number
  title: string
  detail?: string
  errors?: Record<string, unknown>

  constructor(problem: ProblemDetails) {
    super(problem.detail ?? problem.title ?? 'Request failed')
    this.status = problem.status
    this.title = problem.title
    this.detail = problem.detail
    this.errors = problem.errors
  }
}

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE'
  body?: unknown
  token?: string | null
  query?: Record<string, string | number | undefined>
}

export interface ApiResult<T> {
  data: T
  totalCount: number | null
}

export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<ApiResult<T>> {
  const { method = 'GET', body, token, query } = options

  const url = new URL(BASE_URL + path)
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined) url.searchParams.set(key, String(value))
    }
  }

  const headers: Record<string, string> = { 'Content-Type': 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`

  const response = await fetch(url.toString(), {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  const totalCountHeader = response.headers.get('X-Total-Count')
  const totalCount = totalCountHeader === null ? null : Number(totalCountHeader)

  if (response.status === 204) {
    return { data: undefined as T, totalCount }
  }

  const json = await response.json()

  if (!response.ok) {
    throw new ApiError(json as ProblemDetails)
  }

  return { data: json as T, totalCount }
}

// For binary responses (e.g. a gzip export) rather than JSON - errors still
// come back as application/problem+json, so those are parsed and thrown the
// same way apiRequest does.
export async function apiRequestBlob(
  path: string,
  options: { token?: string | null; query?: Record<string, string | number | undefined> } = {},
): Promise<Blob> {
  const url = new URL(BASE_URL + path)
  if (options.query) {
    for (const [key, value] of Object.entries(options.query)) {
      if (value !== undefined) url.searchParams.set(key, String(value))
    }
  }

  const headers: Record<string, string> = {}
  if (options.token) headers.Authorization = `Bearer ${options.token}`

  const response = await fetch(url.toString(), { headers })

  if (!response.ok) {
    throw new ApiError((await response.json()) as ProblemDetails)
  }

  return response.blob()
}
