# frozen_string_literal: true

require 'jwt'

module Backend
  module Jwt
    module_function

    def encode(payload, secret:, ttl:)
      exp = Time.now.to_i + ttl
      JWT.encode(payload.merge(exp: exp), secret, 'HS256')
    end

    # Returns the decoded payload (with string keys), or nil if the token is
    # missing, malformed, or expired.
    def decode(token, secret:)
      decoded, = JWT.decode(token, secret, true, algorithm: 'HS256')
      decoded
    rescue JWT::DecodeError
      nil
    end
  end
end
