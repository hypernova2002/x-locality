# frozen_string_literal: true

require "openssl"
require "base64"

module Backend
  # AES-256-GCM, used to encrypt project-level LLM provider API keys at
  # rest - unlike our own api_keys table, these must be recoverable in
  # plaintext to actually call the provider, so hashing isn't an option.
  module Crypto
    IV_LENGTH = 12
    AUTH_TAG_LENGTH = 16

    module_function

    def encrypt(plaintext, key:)
      return nil if plaintext.nil?

      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = Base64.strict_decode64(key)
      iv = cipher.random_iv
      ciphertext = cipher.update(plaintext) + cipher.final
      Base64.strict_encode64(iv + cipher.auth_tag + ciphertext)
    end

    def decrypt(encoded, key:)
      return nil if encoded.nil?

      raw = Base64.strict_decode64(encoded)
      iv = raw[0, IV_LENGTH]
      auth_tag = raw[IV_LENGTH, AUTH_TAG_LENGTH]
      ciphertext = raw[(IV_LENGTH + AUTH_TAG_LENGTH)..]

      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      cipher.key = Base64.strict_decode64(key)
      cipher.iv = iv
      cipher.auth_tag = auth_tag
      cipher.update(ciphertext) + cipher.final
    end
  end
end
