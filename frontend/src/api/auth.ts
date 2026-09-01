import { apiRequest } from './client'
import type { AuthResponse } from './types'

export function signup(params: { account_name: string; email: string; password: string }) {
  return apiRequest<AuthResponse>('/api/v1/admin/auth/signup', { method: 'POST', body: params })
}

export function login(params: { email: string; password: string }) {
  return apiRequest<AuthResponse>('/api/v1/admin/auth/login', { method: 'POST', body: params })
}
