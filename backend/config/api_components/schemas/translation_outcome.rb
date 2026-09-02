# frozen_string_literal: true

module Schemas
  class TranslationOutcome
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[locale status translated_text detected_language cached],
      properties: {
        locale: { type: :string },
        status: { type: :string, enum: %w[completed failed] },
        translated_text: { type: %i[string null] },
        detected_language: { type: %i[string null] },
        cached: {
          type: :boolean,
          description: 'True if an unchanged, already-completed translation was returned without calling the LLM.'
        }
      }
    )
  end
end
