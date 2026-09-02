# frozen_string_literal: true

module Schemas
  class TranslationItem
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[key source_text],
      properties: {
        key: {
          type: :string,
          pattern: '^[a-zA-Z0-9_-]+$',
          description: 'Stable identifier for this translation, reused across calls to update it. Used ' \
                       'directly in URLs (GET /translations/{key}), so it\'s restricted to characters safe there.'
        },
        source_text: { type: :string },
        source_language: { type: :string, description: 'Optional; enables glossary term matching for this item.' },
        context: {
          type: :array,
          items: { type: :string },
          description: 'Context tag keys, already defined in the project, to steer the translation.'
        }
      }
    )
  end
end
