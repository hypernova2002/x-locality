import { apiRequest } from './client'
import type { Account, AccountUser, User } from './types'

export function getAccount(token: string) {
  return apiRequest<Account>('/api/v1/admin/account', { token })
}

export function updateAccount(
  token: string,
  params: Partial<{
    name: string
    timezone: string
    logo_url: string | null
    correspondence_name: string | null
  }>,
) {
  return apiRequest<Account>('/api/v1/admin/account', {
    method: 'PATCH',
    body: params,
    token,
  })
}

export function listAccountUsers(token: string) {
  return apiRequest<AccountUser[]>('/api/v1/admin/account/users', { token })
}

export function deleteAccountUser(token: string, userId: string) {
  return apiRequest<void>(`/api/v1/admin/account/users/${userId}`, { method: 'DELETE', token })
}

export function transferOwnership(token: string, email: string) {
  return apiRequest<User>('/api/v1/admin/account/transfer_ownership', {
    method: 'POST',
    body: { email },
    token,
  })
}

export function deleteAccount(token: string) {
  return apiRequest<void>('/api/v1/admin/account', { method: 'DELETE', token })
}
