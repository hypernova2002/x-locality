// Shapes mirror the backend's Alba serializers exactly - see backend/app/serializers.

export interface User {
  id: string
  email: string
  role: string
  account_id: string
}

export interface AuthResponse {
  access_token: string
  user: User
}

export interface Account {
  id: string
  name: string
  timezone: string
  logo_url: string | null
  correspondence_name: string | null
  created_at: string
}

export interface Project {
  id: string
  name: string
  slug: string
  created_at: string
  updated_at: string
  my_role?: 'admin' | 'member' | null
}

export type ProjectRole = 'admin' | 'member'

export interface ProjectMember {
  user_id: string
  email: string
  project_role: ProjectRole
  account_role: 'owner' | 'member'
}

export interface Invite {
  id: string
  email: string
  role: ProjectRole
  expires_at: string
  created_at: string
  invited_by_email: string | null
}

export interface InvitePreview {
  email: string
  role: ProjectRole
  project_name: string
  invited_by_email: string | null
}

export interface AccountUser {
  id: string
  email: string
  role: 'owner' | 'member'
  created_at: string
}

export interface LlmConfig {
  monthly_cost_limit_usd: number | null
  monthly_token_limit: number | null
  active_llm_provider_config_id: string | null
  alert_email: string | null
  alert_threshold_percent: number | null
  langfuse_enabled: boolean
  langfuse_public_key: string | null
  langfuse_secret_key_configured: boolean
}

export interface LlmProviderConfig {
  id: string
  name: string
  description: string | null
  provider: string
  model: string | null
  api_key_configured: boolean
  created_at: string
  updated_at: string
}

export interface LlmModelOption {
  id: string
  name: string
}

export interface ApiKey {
  id: string
  name: string
  key: string | null // null once encrypted-at-rest data predates key visibility, or on older rows
  last_used_at: string | null
  revoked_at: string | null
  created_at: string
}

export interface Locale {
  id: string
  key: string
  target_language: string
  style_tone_text: string | null
  general_description: string | null
  system: boolean
  created_at: string
  updated_at: string
}

export interface ContextTag {
  id: string
  key: string
  description: string | null
  created_at: string
  updated_at: string
}

export interface GlossaryTerm {
  id: string
  source_term: string
  source_language: string
  target_term: string
  // null means the mapping applies regardless of target locale (e.g. a
  // brand name that should never be translated).
  target_locale: string | null
  created_at: string
  updated_at: string
}

export type WebhookEventType = 'translation.batch_completed' | 'budget.threshold_crossed'

export interface ProjectWebhook {
  id: string
  url: string
  secret: string
  event_types: WebhookEventType[]
  enabled: boolean
  created_at: string
  updated_at: string
}

export interface WebhookDelivery {
  id: number
  event_type: string
  response_status: number | null
  error_message: string | null
  success: boolean
  created_at: string
}

export interface Translation {
  id: string
  key: string
  locale: string
  source_text: string
  source_language: string | null
  detected_language: string | null
  translated_text: string | null
  status: 'pending' | 'completed' | 'failed'
  generated_by: 'llm' | 'user'
  llm_provider: string | null
  model_used: string | null
  context_tags: string[]
  created_at: string
  updated_at: string
  // Only present on the by_key (translation detail) response.
  usage?: TranslationUsageCounts
}

export interface TranslationSummary {
  id: string
  locale: string
  status: 'pending' | 'completed' | 'failed'
  translated_text: string | null
  generated_by: 'llm' | 'user'
  llm_provider: string | null
  model_used: string | null
  updated_at: string
}

export interface TranslationUsageCounts {
  total_requests: number
  cache_hits: number
  llm_generations: number
}

export interface TranslationGroup {
  key: string
  source_text: string | null
  source_language: string | null
  locked: boolean
  translations: TranslationSummary[]
  usage: TranslationUsageCounts
}

export interface TranslationGroupDetail {
  key: string
  source_text: string
  locked: boolean
  translations: Translation[]
}

export interface TranslationVersion {
  id: string
  previous_value: string | null
  new_value: string | null
  changed_by_type: 'llm' | 'user'
  changed_by_user_email: string | null
  created_at: string
}

export interface ApiUsageData {
  total_requests: number
  successful_requests: number
  failed_requests: number
  total_translations: number
  translations_completed: number
  translations_failed: number
  by_day: { date: string; count: number }[]
}

export interface LlmUsageData {
  total_input_tokens: number
  total_output_tokens: number
  total_cost: number | null
  successful_calls: number
  failed_calls: number
  avg_latency_ms: number | null
  by_day: { date: string; input_tokens: number; output_tokens: number; failed_calls: number }[]
  by_provider_model: {
    provider: string
    model: string
    input_tokens: number
    output_tokens: number
    translation_count: number
    successful_calls: number
    failed_calls: number
    avg_latency_ms: number | null
    cost: number | null
  }[]
  recent_failures: {
    provider: string
    model: string
    error_message: string | null
    created_at: string
  }[]
}

export interface TranslationUsageData {
  total_requests: number
  cache_hits: number
  llm_generations: number
  by_day: { date: string; total_requests: number; cache_hits: number; llm_generations: number }[]
}

// RFC 9457 Problem Details
export interface ProblemDetails {
  type: string
  title: string
  status: number
  detail?: string
  errors?: Record<string, unknown>
}
