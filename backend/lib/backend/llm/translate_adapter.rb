# frozen_string_literal: true

require 'aws-sdk-translate'

module Backend
  module Llm
    # Amazon Translate is a plain NMT service, not an LLM - one API call per
    # item (no batching), no prompt, and no way to apply glossary terms or
    # context tags the way the LLM adapters do (those are silently ignored
    # here; Amazon Translate has its own separate "Custom Terminology"
    # mechanism, not wired up). No model concept either - Translate is a
    # fixed engine, so #list_models always returns [].
    #
    # Billed per character, not per token. input_tokens below actually holds
    # the source character count (what Translate meters); output_tokens is
    # always 0, since Translate has no separate output-side billing
    # dimension. Pricing::RATES prices it accordingly.
    class TranslateAdapter < Base
      # Stands in for a real model id - LlmUsageEvent#llm_model and
      # Pricing::RATES both key off this, and Translate has no model of
      # its own to report.
      MODEL_ID = 'amazon-translate'

      attr_reader :model

      def initialize(access_key_id:, secret_access_key:, region:)
        super()
        @model = MODEL_ID
        @client = Aws::Translate::Client.new(access_key_id: access_key_id, secret_access_key: secret_access_key,
                                             region: region)
      end

      def self.list_models(**)
        []
      end

      def translate(items:, locale:)
        items.map do |item|
          response = @client.translate_text(
            text: item[:source_text],
            source_language_code: item[:source_language] || 'auto',
            target_language_code: locale.target_language
          )

          Result.new(
            key: item[:key],
            translated_text: response.translated_text,
            detected_source_language: response.source_language_code,
            usage: Usage.new(input_tokens: item[:source_text].length, output_tokens: 0)
          )
        end
      end
    end
  end
end
