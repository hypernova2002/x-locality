# frozen_string_literal: true

module SecuritySchemes
  class BearerAuth
    include OpenapiRuby::Components::Base

    component_type :securitySchemes

    schema(
      type: :http,
      scheme: :bearer,
      description: 'A project API key, created from the admin UI\'s Settings > API Keys page.'
    )
  end
end
