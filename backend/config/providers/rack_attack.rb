# frozen_string_literal: true

Hanami.app.register_provider(:rack_attack) do
  prepare do
    require "redis"
    require_relative "../../lib/backend/rack_attack_redis_store"
  end

  start do
    redis = Redis.new(url: target["settings"].rack_attack_redis_url)
    Rack::Attack.cache.store = Backend::RackAttackRedisStore.new(redis)

    # Translation API: throttle per API key, not per IP - these are
    # server-to-server integrations, not browser clients. Raw key value is
    # fine as a throttle discriminator (it's never persisted, only hashed
    # for lookup); avoids depending on auth having already run in an
    # earlier middleware.
    Rack::Attack.throttle("translations/api_key", limit: 100, period: 60) do |req|
      req.get_header("HTTP_AUTHORIZATION")&.sub(/\ABearer /, "") if req.path.start_with?("/api/v1/")
    end

    # Admin login: throttle per IP to blunt credential stuffing.
    Rack::Attack.throttle("admin/login_ip", limit: 10, period: 60) do |req|
      req.ip if req.path == "/admin/v1/auth/login" && req.post?
    end

    Rack::Attack.throttled_response_retry_after_header = true

    Rack::Attack.throttled_responder = lambda do |req|
      match_data = req.env["rack.attack.match_data"]
      now = match_data[:epoch_time]
      reset_at = now + (match_data[:period] - (now % match_data[:period]))

      headers = {
        "Content-Type" => "application/problem+json",
        "RateLimit-Limit" => match_data[:limit].to_s,
        "RateLimit-Remaining" => "0",
        "RateLimit-Reset" => reset_at.to_s,
        "Retry-After" => (reset_at - now).to_s
      }

      body = {
        type: "about:blank",
        title: "Too Many Requests",
        status: 429,
        detail: "Rate limit exceeded, retry after #{reset_at - now} seconds"
      }.to_json

      [429, headers, [body]]
    end

    register "rack_attack", Rack::Attack
  end
end
