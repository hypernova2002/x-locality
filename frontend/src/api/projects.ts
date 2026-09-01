import { apiRequest } from './client'
import type { Project } from './types'

export function listProjects(token: string) {
  return apiRequest<Project[]>('/api/v1/admin/projects', { token })
}

export function getProject(token: string, projectId: string) {
  return apiRequest<Project>(`/api/v1/admin/projects/${projectId}`, { token })
}

export function createProject(token: string, params: { name: string }) {
  return apiRequest<Project>('/api/v1/admin/projects', { method: 'POST', body: params, token })
}

export function updateProject(token: string, projectId: string, params: Partial<{ name: string }>) {
  return apiRequest<Project>(`/api/v1/admin/projects/${projectId}`, {
    method: 'PATCH',
    body: params,
    token,
  })
}

export function deleteProject(token: string, projectId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}`, { method: 'DELETE', token })
}
