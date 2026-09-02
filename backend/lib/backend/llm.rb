# frozen_string_literal: true

module Backend
  module Llm
    def self.for_project(project)
      config = project.llm_config&.active_llm_provider_config

      case config&.provider
      when 'anthropic'
        AnthropicAdapter.new(api_key: config.api_key, model: config.llm_model)
      when 'openai'
        OpenaiAdapter.new(api_key: config.api_key, model: config.llm_model)
      when 'gemini'
        GeminiAdapter.new(api_key: config.api_key, model: config.llm_model)
      when 'bedrock'
        BedrockAdapter.new(access_key_id: config.api_key, secret_access_key: config.api_secret,
                           region: config.region, model: config.llm_model)
      when 'aws_translate'
        TranslateAdapter.new(access_key_id: config.api_key, secret_access_key: config.api_secret,
                             region: config.region)
      else
        raise "Unsupported LLM provider: #{config&.provider.inspect}"
      end
    end

    def self.list_models(provider:, api_key: nil, api_secret: nil, region: nil)
      case provider
      when 'anthropic'
        AnthropicAdapter.list_models(api_key: api_key)
      when 'openai'
        OpenaiAdapter.list_models(api_key: api_key)
      when 'gemini'
        GeminiAdapter.list_models(api_key: api_key)
      when 'bedrock'
        BedrockAdapter.list_models(access_key_id: api_key, secret_access_key: api_secret, region: region)
      when 'aws_translate'
        TranslateAdapter.list_models
      else
        raise "Unsupported LLM provider: #{provider.inspect}"
      end
    end
  end
end
