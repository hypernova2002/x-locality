# frozen_string_literal: true

require 'hanami'
require 'rack/attack'
require 'rack/cors'
require 'alba'
require_relative '../lib/backend/not_found_json'
require_relative '../lib/backend/time_json_format'
require_relative 'openapi_ruby'

module Backend
  class App < Hanami::App
    # First in the stack so it reads (and rewinds) the raw request body
    # before Hanami's own params parsing consumes it.
    OpenapiRuby::Hanami.install_middleware!(config)

    config.middleware.use Backend::NotFoundJSON
    config.middleware.use Rack::Attack
    config.actions.formats.accept :json
  end
end
