# frozen_string_literal: true

module Backend
  # Rack::Attack.cache.store expects an ActiveSupport::Cache::Store-shaped
  # object (#read/#write/#increment/#delete). We avoid pulling in ActiveSupport
  # just for this, so this is a minimal adapter over the `redis` gem.
  class RackAttackRedisStore
    def initialize(redis)
      @redis = redis
    end

    def read(key)
      @redis.get(key)
    end

    def write(key, value, options = {})
      if (ttl = options[:expires_in])
        @redis.set(key, value, ex: ttl.to_i)
      else
        @redis.set(key, value)
      end
    end

    def increment(key, amount = 1, options = {})
      count = @redis.incrby(key, amount)
      ttl = options[:expires_in]
      @redis.expire(key, ttl.to_i) if ttl && count == amount
      count
    end

    def delete(key)
      @redis.del(key)
    end
  end
end
