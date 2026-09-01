# auto_register: false
# frozen_string_literal: true

require "hanami/action"
require "dry/monads"

module Backend
  class Action < Hanami::Action
    # Provide `Success` and `Failure` for pattern matching on operation results
    include Dry::Monads[:result]

    private

    # RFC 9457 Problem Details (application/problem+json). `status` must be
    # the integer code (not a symbol) since it's also written into the body.
    def render_problem(response, status:, title:, detail: nil, errors: nil)
      response.format = :json
      body = { type: "about:blank", title: title, status: status }
      body[:detail] = detail if detail
      body[:errors] = errors if errors
      halt status, body.to_json
    end

    # Operations (app/**/*.rb, Dry::Operation subclasses) fail with a
    # [code, detail] pair via Dry::Monads::Failure. This is the single place
    # that maps those codes to HTTP status/title, so every action renders
    # operation failures consistently.
    FAILURE_STATUSES = {
      conflict: 409, unauthorized: 401, forbidden: 403, not_found: 404,
      validation: 422, unconfigured: 422, budget_exceeded: 402
    }.freeze

    FAILURE_TITLES = {
      conflict: "Conflict", unauthorized: "Unauthorized", forbidden: "Forbidden",
      not_found: "Not Found", validation: "Unprocessable Entity", unconfigured: "Unprocessable Entity",
      budget_exceeded: "Payment Required"
    }.freeze

    def render_failure(response, code, detail)
      status = FAILURE_STATUSES.fetch(code, 422)
      render_problem(response, status: status, title: FAILURE_TITLES.fetch(code, "Error"), detail: detail)
    end
  end
end
