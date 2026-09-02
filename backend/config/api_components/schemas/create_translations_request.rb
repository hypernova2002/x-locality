# frozen_string_literal: true

module Schemas
  class CreateTranslationsRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[target_locales items],
      properties: {
        target_locales: {
          type: :array,
          items: { type: :string },
          description: 'Locale keys already defined in the project.'
        },
        items: { type: :array, items: { '$ref' => '#/components/schemas/TranslationItem' } }
      }
    )
  end
end
