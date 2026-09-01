# frozen_string_literal: true

module Backend
  module LlmConfigs
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent.
      def call(project:, updates:)
        config = project.llm_config || Backend::Models::LlmConfig.create(project_id: project.id)

        if updates.key?(:active_llm_provider_config_id)
          step set_active(project, config, updates[:active_llm_provider_config_id])
        end

        config.monthly_cost_limit_usd = updates[:monthly_cost_limit_usd] if updates.key?(:monthly_cost_limit_usd)
        config.monthly_token_limit = updates[:monthly_token_limit] if updates.key?(:monthly_token_limit)

        if updates.key?(:alert_email) || updates.key?(:alert_threshold_percent)
          config.alert_email = updates[:alert_email] if updates.key?(:alert_email)
          config.alert_threshold_percent = updates[:alert_threshold_percent] if updates.key?(:alert_threshold_percent)
          # New alert settings should be able to fire again this month rather
          # than staying silenced by a month-marker set under the old ones.
          config.alert_sent_for_month = nil
        end

        config.langfuse_enabled = updates[:langfuse_enabled] if updates.key?(:langfuse_enabled)
        config.langfuse_public_key = updates[:langfuse_public_key] if updates.key?(:langfuse_public_key)
        # "Leave the currently-saved secret alone" is the frontend omitting
        # this key entirely when its masked field is left blank (mirrors
        # LlmProviderConfig#api_key) - not a blank-string check here.
        config.langfuse_secret_key = updates[:langfuse_secret_key] if updates.key?(:langfuse_secret_key)

        config.save

        config
      end

      private

      def set_active(project, config, public_id)
        if public_id.nil?
          config.active_llm_provider_config_id = nil
          return Success(true)
        end

        provider_config = project.llm_provider_configs_dataset.first(public_id: public_id)
        return Failure([:not_found, "LLM provider config not found"]) unless provider_config

        config.active_llm_provider_config_id = provider_config.id
        Success(true)
      end
    end
  end
end
