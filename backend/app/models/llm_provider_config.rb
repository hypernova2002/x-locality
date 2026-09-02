# frozen_string_literal: true

module Backend
  module Models
    class LlmProviderConfig < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'llmpc'

      many_to_one :project

      def api_key=(plaintext)
        self.api_key_ciphertext = if plaintext.nil? || plaintext.empty?
                                    nil
                                  else
                                    Backend::Crypto.encrypt(
                                      plaintext, key: Hanami.app['settings'].encryption_key
                                    )
                                  end
      end

      def api_key
        return nil if api_key_ciphertext.nil?

        Backend::Crypto.decrypt(api_key_ciphertext, key: Hanami.app['settings'].encryption_key)
      end

      def api_key_configured?
        !api_key_ciphertext.nil?
      end

      # AWS-backed providers (Bedrock, Amazon Translate) need a secret access
      # key alongside the access key id stored in api_key.
      def api_secret=(plaintext)
        self.api_secret_ciphertext = if plaintext.nil? || plaintext.empty?
                                       nil
                                     else
                                       Backend::Crypto.encrypt(
                                         plaintext, key: Hanami.app['settings'].encryption_key
                                       )
                                     end
      end

      def api_secret
        return nil if api_secret_ciphertext.nil?

        Backend::Crypto.decrypt(api_secret_ciphertext, key: Hanami.app['settings'].encryption_key)
      end

      def api_secret_configured?
        !api_secret_ciphertext.nil?
      end
    end
  end
end
