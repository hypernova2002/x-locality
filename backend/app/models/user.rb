# frozen_string_literal: true

require 'bcrypt'

module Backend
  module Models
    class User < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'user'

      many_to_one :account
      one_to_many :project_memberships

      def owner?
        role == 'owner'
      end

      def password=(plaintext)
        self.password_digest = BCrypt::Password.create(plaintext)
      end

      def authenticate(plaintext)
        digest = BCrypt::Password.new(password_digest)
        digest.is_a?(BCrypt::Password) && digest == plaintext ? self : false
      end
    end
  end
end
