# frozen_string_literal: true

module Backend
  module Models
    # Project-level LLM settings: which saved LlmProviderConfig is currently
    # active, plus the monthly spend/token caps. The provider/model/API key
    # themselves live on LlmProviderConfig so a project can keep several
    # saved and switch between them without re-entering credentials.
    class LlmConfig < Sequel::Model
      many_to_one :project
      many_to_one :active_llm_provider_config, class: 'Backend::Models::LlmProviderConfig'

      def langfuse_secret_key=(plaintext)
        self.langfuse_secret_key_ciphertext = if plaintext.nil? || plaintext.empty?
                                                nil
                                              else
                                                Backend::Crypto.encrypt(
                                                  plaintext, key: Hanami.app['settings'].encryption_key
                                                )
                                              end
      end

      def langfuse_secret_key
        return nil if langfuse_secret_key_ciphertext.nil?

        Backend::Crypto.decrypt(langfuse_secret_key_ciphertext, key: Hanami.app['settings'].encryption_key)
      end

      def langfuse_secret_key_configured?
        !langfuse_secret_key_ciphertext.nil?
      end

      def langfuse_configured?
        langfuse_enabled && !langfuse_public_key.to_s.empty? && langfuse_secret_key_configured?
      end
    end
  end
end
