import { apiRequest } from './client'
import type { AuthResponse, Invite, InvitePreview, ProjectRole } from './types'

export function listInvites(token: string, projectId: string) {
  return apiRequest<Invite[]>(`/api/v1/admin/projects/${projectId}/invites`, { token })
}

export function createInvite(token: string, projectId: string, params: { email: string; role: ProjectRole }) {
  return apiRequest<Invite>(`/api/v1/admin/projects/${projectId}/invites`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function deleteInvite(token: string, projectId: string, inviteId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/invites/${inviteId}`, {
    method: 'DELETE',
    token,
  })
}

// Public - no auth, the invited person doesn't have an account yet.
export function previewInvite(inviteToken: string) {
  return apiRequest<InvitePreview>(`/api/v1/admin/invites/${inviteToken}`)
}

export function acceptInvite(inviteToken: string, password: string) {
  return apiRequest<AuthResponse>(`/api/v1/admin/invites/${inviteToken}/accept`, {
    method: 'POST',
    body: { password },
  })
}
