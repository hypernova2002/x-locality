# frozen_string_literal: true

require "hanami"
require "rack/attack"
require "rack/cors"
require "alba"
require_relative "../lib/backend/not_found_json"
require_relative "../lib/backend/time_json_format"

module Backend
  class App < Hanami::App
    config.middleware.use Backend::NotFoundJSON
    config.middleware.use Rack::Attack
    config.actions.formats.accept :json
  end
end
