# frozen_string_literal: true

require 'securerandom'
require 'digest'

module Backend
  module Models
    class APIKey < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'apikey'

      PREFIX = 'xloc_'

      many_to_one :project
      many_to_one :created_by_user, class: User, key: :created_by_user_id

      class << self
        # Returns the created record - the plaintext key is available via
        # `record.key` right after, same as any other time (it's encrypted
        # at rest, not one-time-only - see key=/key below).
        def generate(project:, name:, created_by_user: nil)
          plaintext = "#{PREFIX}#{SecureRandom.urlsafe_base64(32)}"
          record = create(
            project: project,
            name: name,
            created_by_user: created_by_user,
            key_digest: digest(plaintext)
          )
          record.key = plaintext
          record.save
          record
        end

        def authenticate(plaintext)
          return nil if plaintext.nil? || plaintext.empty?

          first(key_digest: digest(plaintext), revoked_at: nil)
        end

        def digest(plaintext)
          Digest::SHA256.hexdigest(plaintext)
        end
      end

      def revoked?
        !revoked_at.nil?
      end

      def key=(plaintext)
        self.key_ciphertext = if plaintext.nil?
                                nil
                              else
                                Backend::Crypto.encrypt(plaintext,
                                                        key: Hanami.app['settings'].encryption_key)
                              end
      end

      def key
        return nil if key_ciphertext.nil?

        Backend::Crypto.decrypt(key_ciphertext, key: Hanami.app['settings'].encryption_key)
      end
    end
  end
end
