# frozen_string_literal: true

require 'openapi_ruby/hanami'

OpenapiRuby.configure do |config|
  config.schemas = {
    public_api: {
      info: {
        title: 'XLocality API',
        version: 'v1',
        description: 'External, API-key-authenticated translation API. ' \
                     'The admin UI\'s own JWT-authenticated endpoints are not part of this document.'
      },
      servers: [{ url: '/api/v1' }],
      prefix: '/api/v1'
    }
  }

  # This API's wire format is snake_case throughout - the gem's camelCase
  # default would otherwise document (and validate against) field names the
  # API doesn't actually accept.
  config.camelize_keys = false

  config.request_validation = :enabled
  config.response_validation = :enabled
  config.ui_enabled = true
end
