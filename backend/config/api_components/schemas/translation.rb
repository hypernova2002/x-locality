# frozen_string_literal: true

module Schemas
  class Translation
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[id key source_text source_language detected_language translated_text status generated_by
                   llm_provider model_used locale context_tags created_at updated_at],
      properties: {
        id: { type: :string, description: 'Public identifier, e.g. "tran_abc123".' },
        key: { type: :string },
        source_text: { type: :string },
        source_language: { type: %i[string null] },
        detected_language: { type: %i[string null] },
        translated_text: { type: %i[string null] },
        status: { type: :string, enum: %w[pending completed failed] },
        generated_by: { type: :string, enum: %w[llm user] },
        llm_provider: { type: %i[string null] },
        model_used: { type: %i[string null] },
        locale: { type: :string, description: 'The locale key this translation belongs to.' },
        context_tags: { type: :array, items: { type: :string } },
        created_at: { type: :string, format: 'date-time' },
        updated_at: { type: :string, format: 'date-time' }
      }
    )
  end
end
