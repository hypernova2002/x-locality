import { apiRequest } from './client'
import type { ProjectMember, ProjectRole } from './types'

export function listMembers(token: string, projectId: string) {
  return apiRequest<ProjectMember[]>(`/api/v1/admin/projects/${projectId}/members`, { token })
}

export function addMember(token: string, projectId: string, params: { email: string; role: ProjectRole }) {
  return apiRequest<ProjectMember>(`/api/v1/admin/projects/${projectId}/members`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function updateMemberRole(token: string, projectId: string, userId: string, role: ProjectRole) {
  return apiRequest<ProjectMember>(`/api/v1/admin/projects/${projectId}/members/${userId}`, {
    method: 'PATCH',
    body: { role },
    token,
  })
}

export function removeMember(token: string, projectId: string, userId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/members/${userId}`, {
    method: 'DELETE',
    token,
  })
}
