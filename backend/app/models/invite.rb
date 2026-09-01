# frozen_string_literal: true

require "securerandom"
require "digest"

module Backend
  module Models
    class Invite < Sequel::Model
      include Concerns::HasPublicId
      public_id_prefix "invite"

      TTL = 7 * 24 * 60 * 60 # 7 days

      many_to_one :account
      many_to_one :project
      many_to_one :invited_by_user, class: User, key: :invited_by_user_id

      class << self
        # Returns [invite, plaintext_token] - the plaintext only ever exists
        # here and in the email that gets sent; only its digest is stored.
        def generate(account:, project:, email:, role:, invited_by_user: nil)
          plaintext = SecureRandom.urlsafe_base64(32)
          invite = create(
            account: account, project: project, email: email, role: role,
            invited_by_user: invited_by_user, token_digest: digest(plaintext),
            expires_at: Time.now + TTL
          )
          [invite, plaintext]
        end

        def find_by_token(plaintext)
          return nil if plaintext.nil? || plaintext.empty?

          first(token_digest: digest(plaintext))
        end

        def digest(plaintext)
          Digest::SHA256.hexdigest(plaintext)
        end
      end

      def expired?
        expires_at < Time.now
      end

      def accepted?
        !accepted_at.nil?
      end

      def pending?
        !accepted? && !expired?
      end
    end
  end
end
