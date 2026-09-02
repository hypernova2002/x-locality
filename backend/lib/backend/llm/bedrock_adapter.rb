# frozen_string_literal: true

require 'aws-sdk-bedrock'
require 'aws-sdk-bedrockruntime'

module Backend
  module Llm
    # Amazon Bedrock gives access to many underlying models (Claude, Llama,
    # Titan, Mistral, ...) through one API - Converse, with tool use for
    # structured output, same shape regardless of the underlying model. No
    # default model: unlike Anthropic/Gemini there's no single well-known
    # Bedrock model id stable enough to hardcode, and the model must support
    # tool use in Converse (not every Bedrock model does) - callers must
    # configure one explicitly.
    class BedrockAdapter < Base
      TOOL_CONFIG = {
        tools: [
          {
            tool_spec: {
              name: 'record_translations',
              description: 'Record the translated text for each provided item, matched back by key.',
              input_schema: {
                json: {
                  type: 'object',
                  properties: {
                    translations: {
                      type: 'array',
                      items: {
                        type: 'object',
                        properties: {
                          key: { type: 'string', description: 'Echo back the exact key of the source item.' },
                          translated_text: { type: 'string' },
                          detected_source_language: {
                            type: 'string',
                            description: 'ISO 639-1 code of the detected source language.'
                          }
                        },
                        required: %w[key translated_text detected_source_language]
                      }
                    }
                  },
                  required: ['translations']
                }
              }
            }
          }
        ],
        tool_choice: { tool: { name: 'record_translations' } }
      }.freeze

      attr_reader :model

      def initialize(access_key_id:, secret_access_key:, region:, model: nil)
        super()
        raise ArgumentError, 'model is required for Bedrock' if model.nil? || model.empty?

        credentials = { access_key_id: access_key_id, secret_access_key: secret_access_key, region: region }
        @runtime_client = Aws::BedrockRuntime::Client.new(**credentials)
        @control_client = Aws::Bedrock::Client.new(**credentials)
        @model = model
      end

      # Text-capable, on-demand models only - a filtered slice of the full
      # catalog (which also lists image/embedding models and
      # provisioned-throughput-only entries not usable here).
      def self.list_models(access_key_id:, secret_access_key:, region:)
        client = Aws::Bedrock::Client.new(access_key_id: access_key_id, secret_access_key: secret_access_key,
                                          region: region)
        client.list_foundation_models.model_summaries
              .select { |m| m.input_modalities.include?('TEXT') && m.output_modalities.include?('TEXT') }
              .map { |m| { id: m.model_id, name: "#{m.provider_name} #{m.model_name}" } }
      end

      def translate(items:, locale:)
        return [] if items.empty?

        response = @runtime_client.converse(
          model_id: model,
          messages: [{ role: 'user', content: [{ text: build_prompt(items: items, locale: locale) }] }],
          tool_config: TOOL_CONFIG
        )

        tool_use_block = response.output.message.content.find(&:tool_use)
        raise 'Bedrock did not return a tool call' unless tool_use_block

        usage = Usage.new(input_tokens: response.usage.input_tokens, output_tokens: response.usage.output_tokens)

        tool_use_block.tool_use.input['translations'].map do |entry|
          Result.new(
            key: entry['key'],
            translated_text: entry['translated_text'],
            detected_source_language: entry['detected_source_language'],
            usage: usage
          )
        end
      end
    end
  end
end
