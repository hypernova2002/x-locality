# frozen_string_literal: true

require 'openai'

module Backend
  module Llm
    class OpenaiAdapter < Base
      DEFAULT_MODEL = 'gpt-5.2'

      RESPONSE_SCHEMA = {
        type: :json_schema,
        name: 'record_translations',
        strict: true,
        schema: {
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
        }
      }.freeze

      attr_reader :model

      def initialize(api_key:, model: nil)
        super()
        @client = OpenAI::Client.new(api_key: api_key)
        @model = model.nil? || model.empty? ? DEFAULT_MODEL : model
      end

      def self.list_models(api_key:)
        client = OpenAI::Client.new(api_key: api_key)
        client.models.list.data.map { |m| { id: m.id, name: m.id } }
      end

      def translate(items:, locale:)
        return [] if items.empty?

        response = @client.responses.create(
          model: model,
          input: [{ role: :user, content: build_prompt(items: items, locale: locale) }],
          text: { format: RESPONSE_SCHEMA }
        )

        message = response.output.grep(OpenAI::Responses::ResponseOutputMessage).first
        raise 'OpenAI did not return a message' unless message

        output_text = message.content.grep(OpenAI::Responses::ResponseOutputText).first
        raise 'OpenAI did not return structured text output' unless output_text

        usage = Usage.new(input_tokens: response.usage.input_tokens, output_tokens: response.usage.output_tokens)

        JSON.parse(output_text.text)['translations'].map do |entry|
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
