# frozen_string_literal: true

module Backend
  module LlmProviderConfigs
    class Create < Backend::Operation
      def call(project:, name:, provider:, description: nil, model: nil, api_key: nil)
        config = Backend::Models::LlmProviderConfig.new(
          project_id: project.id, name: name, description: description,
          provider: provider, llm_model: model
        )
        config.api_key = api_key if api_key
        config.save

        config
      end
    end
  end
end
