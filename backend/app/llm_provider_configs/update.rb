# frozen_string_literal: true

module Backend
  module LlmProviderConfigs
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent.
      def call(config:, updates:)
        config.name = updates[:name] if updates.key?(:name)
        config.description = updates[:description] if updates.key?(:description)
        config.provider = updates[:provider] if updates.key?(:provider)
        config.llm_model = updates[:model] if updates.key?(:model)
        config.api_key = updates[:api_key] if updates.key?(:api_key)
        config.save

        config
      end
    end
  end
end
