# frozen_string_literal: true

module Backend
  module Serializers
    class LlmConfigSerializer
      include Alba::Resource

      attributes :monthly_token_limit, :alert_email, :alert_threshold_percent,
                 :langfuse_enabled, :langfuse_public_key

      attribute :monthly_cost_limit_usd do |config|
        config.monthly_cost_limit_usd&.to_f
      end

      attribute :active_llm_provider_config_id do |config|
        config.active_llm_provider_config&.public_id
      end

      attribute :langfuse_secret_key_configured, &:langfuse_secret_key_configured?
    end
  end
end
