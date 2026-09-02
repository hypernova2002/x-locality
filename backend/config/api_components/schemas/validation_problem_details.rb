# frozen_string_literal: true

module Schemas
  class ValidationProblemDetails < Schemas::ProblemDetails
    include OpenapiRuby::Components::Base

    schema(
      properties: {
        errors: {
          type: :object,
          description: 'Field name(s) mapped to an array of validation failure messages. Nested for array/hash ' \
                       'fields, e.g. {"items" => {"0" => {"key" => ["is missing"]}}}.',
          additionalProperties: true
        }
      }
    )
  end
end
