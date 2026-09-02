# frozen_string_literal: true

module Schemas
  class TranslationCreateResult
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[key translations],
      properties: {
        key: { type: :string },
        translations: { type: :array, items: { '$ref' => '#/components/schemas/TranslationOutcome' } }
      }
    )
  end
end
