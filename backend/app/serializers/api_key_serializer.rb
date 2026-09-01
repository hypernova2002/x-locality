# frozen_string_literal: true

module Backend
  module Serializers
    # Never includes key_digest - only the encrypted-at-rest key, decrypted
    # here for display. Listing/showing a key is intentional (see
    # ApiKey#key) - this is no longer a one-time-reveal.
    class APIKeySerializer
      include Alba::Resource

      attributes :name, :key, :last_used_at, :revoked_at, :created_at

      attribute :id, &:public_id
    end
  end
end
