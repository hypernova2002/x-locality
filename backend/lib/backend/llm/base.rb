# frozen_string_literal: true

module Backend
  module Llm
    class Base
      # items: Array of { key:, source_text:, source_language: (nullable), context_tags: [Backend::Models::ContextTag] }
      # locale: Backend::Models::Locale
      # Returns Array<Backend::Llm::Result>, matched back to items by key -
      # never rely on response ordering matching input ordering.
      def translate(items:, locale:)
        raise NotImplementedError
      end

      private

      # Shared prompt text - every adapter wraps this in its own
      # schema/tool-call mechanism to get structured JSON back.
      def build_prompt(items:, locale:)
        lines = ["Translate each of the following items into #{locale.target_language}."]
        lines << "Style/tone: #{locale.style_tone_text}" if locale.style_tone_text && !locale.style_tone_text.empty?
        lines << ''
        lines << 'Items (respond with exactly one translation per key, echoing the key exactly):'

        items.each do |item|
          lines << "- key: #{item[:key]}"
          lines << "  text: #{item[:source_text]}"
          lines << "  source_language: #{item[:source_language]}" if item[:source_language]
          unless item[:context_tags].nil? || item[:context_tags].empty?
            lines << "  context: #{item[:context_tags].map { |tag| "#{tag.key} (#{tag.description})" }.join(', ')}"
          end
          next if item[:glossary_terms].nil? || item[:glossary_terms].empty?

          glossary = item[:glossary_terms].map do |term|
            "if relevant, translate \"#{term.source_term}\" as \"#{term.target_term}\""
          end.join('; ')
          lines << "  glossary: #{glossary}"
        end

        lines.join("\n")
      end
    end
  end
end
