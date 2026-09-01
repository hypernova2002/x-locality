# frozen_string_literal: true

require 'gemini'

module Backend
  module Llm
    class GeminiAdapter < Base
      # Flash tier, not Pro - meaningfully cheaper and plenty capable for
      # translation. Confirmed as a real, stable (non-preview) model id
      # against https://ai.google.dev/gemini-api/docs/models. Override via
      # a project's llm_model for anything else.
      DEFAULT_MODEL = 'gemini-3.5-flash'

      RESPONSE_SCHEMA = {
        type: 'object',
        properties: {
          translations: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                key: { type: 'string' },
                translated_text: { type: 'string' },
                detected_source_language: { type: 'string' }
              },
              required: %w[key translated_text detected_source_language]
            }
          }
        },
        required: ['translations']
      }.freeze

      attr_reader :model

      def initialize(api_key:, model: nil)
        @model = model.nil? || model.empty? ? DEFAULT_MODEL : model
        @client = Gemini::Client.new(api_key)
      end

      # `name` comes back as "models/gemini-3.5-flash" - strip the prefix
      # since every other model id in this app (including what we send
      # back to the Gemini API itself) is bare.
      def self.list_models(api_key:)
        client = Gemini::Client.new(api_key)
        response = client.models.list
        (response['models'] || []).map do |m|
          { id: m['name'].to_s.sub('models/', ''), name: m['displayName'] || m['name'] }
        end
      end

      def translate(items:, locale:)
        return [] if items.empty?

        response = @client.generate_content(
          build_prompt(items: items, locale: locale),
          model: model,
          response_mime_type: 'application/json',
          response_schema: RESPONSE_SCHEMA
        )

        raise "Gemini request failed: #{response.error}" unless response.success?

        usage = Usage.new(input_tokens: response.prompt_tokens, output_tokens: response.completion_tokens)

        response.json['translations'].map do |entry|
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
