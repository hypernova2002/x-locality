# frozen_string_literal: true

# RFC 9457 Problem Details (application/problem+json), the shape every error
# response on this API shares.
module Schemas
  class ProblemDetails
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[type title status],
      properties: {
        type: { type: :string, description: 'Always "about:blank" - no distinct problem types are defined.' },
        title: { type: :string },
        status: { type: :integer },
        detail: { type: :string }
      }
    )
  end
end
