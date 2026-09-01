# frozen_string_literal: true

module Backend
  # Hanami's router raises Hanami::Router::NotFoundError/NotAllowedError for
  # unmatched routes rather than returning a plain Rack 404 - by design, so
  # they flow through the same error pipeline as any other exception. That
  # pipeline (config.render_errors) is HTML-page-oriented and off in
  # development, so left alone these reach Puma as an unhandled exception
  # (a 500 debug page). This middleware is registered outermost specifically
  # to turn just those two into clean RFC 9457 JSON responses, independent
  # of render_errors - which stays off so genuine bugs still get a full
  # backtrace in development.
  class NotFoundJSON
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Hanami::Router::NotFoundError
      problem(404, 'Not Found', 'No route matches this request')
    rescue Hanami::Router::NotAllowedError
      problem(405, 'Method Not Allowed', 'This route does not support that HTTP method')
    end

    private

    def problem(status, title, detail)
      body = { type: 'about:blank', title: title, status: status, detail: detail }.to_json
      [status, { 'Content-Type' => 'application/problem+json' }, [body]]
    end
  end
end
