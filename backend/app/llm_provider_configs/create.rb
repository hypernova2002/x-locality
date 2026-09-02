# frozen_string_literal: true

module Backend
  module LlmProviderConfigs
    class Create < Backend::Operation
      def call(project:, name:, provider:, description: nil, model: nil, api_key: nil, api_secret: nil, region: nil)
        config = Backend::Models::LlmProviderConfig.new(
          project_id: project.id, name: name, description: description,
          provider: provider, llm_model: model, region: region
        )
        config.api_key = api_key if api_key
        config.api_secret = api_secret if api_secret
        config.save

        config
      end
    end
  end
end
