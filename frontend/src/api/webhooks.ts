import { apiRequest } from './client'
import type { ProjectWebhook, WebhookDelivery, WebhookEventType } from './types'

export interface WebhooksPage {
  webhooks: ProjectWebhook[]
  total: number
}

export async function listWebhooks(
  token: string,
  projectId: string,
  params: { offset?: number; limit?: number } = {},
): Promise<WebhooksPage> {
  const { data, totalCount } = await apiRequest<ProjectWebhook[]>(
    `/api/v1/admin/projects/${projectId}/webhooks`,
    { token, query: params },
  )
  return { webhooks: data, total: totalCount ?? data.length }
}

export function createWebhook(
  token: string,
  projectId: string,
  params: { url: string; event_types: WebhookEventType[] },
) {
  return apiRequest<ProjectWebhook>(`/api/v1/admin/projects/${projectId}/webhooks`, {
    method: 'POST',
    body: params,
    token,
  })
}

export function updateWebhook(
  token: string,
  projectId: string,
  webhookId: string,
  params: Partial<{ url: string; event_types: WebhookEventType[]; enabled: boolean }>,
) {
  return apiRequest<ProjectWebhook>(`/api/v1/admin/projects/${projectId}/webhooks/${webhookId}`, {
    method: 'PATCH',
    body: params,
    token,
  })
}

export function deleteWebhook(token: string, projectId: string, webhookId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/webhooks/${webhookId}`, {
    method: 'DELETE',
    token,
  })
}

export function testWebhook(token: string, projectId: string, webhookId: string) {
  return apiRequest<void>(`/api/v1/admin/projects/${projectId}/webhooks/${webhookId}/test`, {
    method: 'POST',
    token,
  })
}

export interface WebhookDeliveriesPage {
  deliveries: WebhookDelivery[]
  total: number
}

export async function listWebhookDeliveries(
  token: string,
  projectId: string,
  webhookId: string,
  params: { offset?: number; limit?: number } = {},
): Promise<WebhookDeliveriesPage> {
  const { data, totalCount } = await apiRequest<WebhookDelivery[]>(
    `/api/v1/admin/projects/${projectId}/webhooks/${webhookId}/deliveries`,
    { token, query: params },
  )
  return { deliveries: data, total: totalCount ?? data.length }
}
