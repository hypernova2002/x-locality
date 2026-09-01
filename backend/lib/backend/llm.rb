# frozen_string_literal: true

module Backend
  module Llm
    def self.for_project(project)
      config = project.llm_config&.active_llm_provider_config

      case config&.provider
      when "anthropic"
        AnthropicAdapter.new(api_key: config.api_key, model: config.llm_model)
      when "gemini"
        GeminiAdapter.new(api_key: config.api_key, model: config.llm_model)
      else
        raise "Unsupported LLM provider: #{config&.provider.inspect}"
      end
    end

    def self.list_models(provider:, api_key:)
      case provider
      when "anthropic"
        AnthropicAdapter.list_models(api_key: api_key)
      when "gemini"
        GeminiAdapter.list_models(api_key: api_key)
      else
        raise "Unsupported LLM provider: #{provider.inspect}"
      end
    end
  end
end
