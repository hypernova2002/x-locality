# frozen_string_literal: true

Hanami.app.register_provider(:sidekiq) do
  prepare do
    require "sidekiq"
  end

  start do
    redis_url = target["settings"].sidekiq_redis_url

    Sidekiq.configure_client do |config|
      config.redis = { url: redis_url }
    end

    Sidekiq.configure_server do |config|
      config.redis = { url: redis_url }
    end
  end
end
