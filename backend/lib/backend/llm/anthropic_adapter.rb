# frozen_string_literal: true

require 'anthropic'

module Backend
  module Llm
    class AnthropicAdapter < Base
      DEFAULT_MODEL = 'claude-opus-5'

      attr_reader :model

      TOOL = {
        name: 'record_translations',
        description: 'Record the translated text for each provided item, matched back by key.',
        input_schema: {
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
                required: %w[key translated_text detected_source_language],
                additionalProperties: false
              }
            }
          },
          required: ['translations'],
          additionalProperties: false
        },
        strict: true
      }.freeze

      def initialize(api_key:, model: nil)
        @client = Anthropic::Client.new(api_key: api_key)
        @model = model.nil? || model.empty? ? DEFAULT_MODEL : model
      end

      # Real models available to this API key, most-recently-released
      # first (the API's own default ordering) - `.data` is the current
      # page only, no auto-pagination, which is fine for a provider with a
      # small, stable model catalog like Anthropic's.
      def self.list_models(api_key:)
        client = Anthropic::Client.new(api_key: api_key)
        client.models.list(limit: 100).data.map { |m| { id: m.id, name: m.display_name } }
      end

      def translate(items:, locale:)
        return [] if items.empty?

        response = @client.messages.create(
          model: model,
          max_tokens: 4096,
          tools: [TOOL],
          tool_choice: { type: 'tool', name: TOOL[:name] },
          messages: [{ role: 'user', content: build_prompt(items: items, locale: locale) }]
        )

        tool_use = response.content.find { |block| block.type == :tool_use }
        raise 'Anthropic did not return a tool call' unless tool_use

        usage = Usage.new(input_tokens: response.usage.input_tokens, output_tokens: response.usage.output_tokens)

        tool_use.input['translations'].map do |entry|
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
