# frozen_string_literal: true

module Backend
  class Settings < Hanami::Settings
    setting :database_url, constructor: Types::String

    setting :sidekiq_redis_url, constructor: Types::String
    setting :rack_attack_redis_url, constructor: Types::String

    setting :jwt_secret, constructor: Types::String
    setting :jwt_access_token_ttl, default: 86_400, constructor: Types::Params::Integer
    setting :jwt_refresh_token_ttl, default: 2_592_000, constructor: Types::Params::Integer

    setting :cors_allowed_origins,
            default: '',
            constructor: ->(value) { value.to_s.split(',').map(&:strip).reject(&:empty?) }

    setting :sync_translation_unit_limit, default: 50, constructor: Types::Params::Integer
    setting :batch_translation_unit_limit, default: 1_000, constructor: Types::Params::Integer

    # Base64-encoded 32-byte key, used to encrypt project-level LLM API
    # keys at rest (see lib/backend/crypto.rb). LLM provider/API key
    # themselves are per-project settings, not global config.
    setting :encryption_key, constructor: Types::String

    # Budget alert emails - defaults point at the MailHog dev container;
    # swap for a real SMTP provider's host/port in production.
    setting :smtp_host, default: 'mailhog', constructor: Types::String
    setting :smtp_port, default: 1025, constructor: Types::Params::Integer
    setting :mail_from, default: 'alerts@x-locality.local', constructor: Types::String

    # Used to build the invite-accept link in invite emails - the frontend
    # origin, not this API's own.
    setting :frontend_base_url, default: 'http://localhost:5173', constructor: Types::String

    # Self-hosted Langfuse instance (see docker-compose.yml's langfuse-web
    # service) that project-level LLM call tracing sends OTLP traces to.
    # Empty means tracing is unavailable regardless of any project's own
    # langfuse_enabled setting.
    setting :langfuse_base_url, default: '', constructor: Types::String
  end
end
