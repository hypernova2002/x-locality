# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'securerandom'

RSpec.describe Backend::Crypto do
  let(:key) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }

  describe '.encrypt / .decrypt' do
    it 'round-trips plaintext' do
      ciphertext = described_class.encrypt('sk-ant-super-secret', key: key)

      expect(described_class.decrypt(ciphertext, key: key)).to eq('sk-ant-super-secret')
    end

    it 'produces different ciphertext each time (random iv)' do
      a = described_class.encrypt('same-plaintext', key: key)
      b = described_class.encrypt('same-plaintext', key: key)

      expect(a).not_to eq(b)
    end

    it 'returns nil for nil plaintext' do
      expect(described_class.encrypt(nil, key: key)).to be_nil
    end

    it 'returns nil for nil ciphertext' do
      expect(described_class.decrypt(nil, key: key)).to be_nil
    end

    it 'fails to decrypt with the wrong key' do
      ciphertext = described_class.encrypt('secret', key: key)
      wrong_key = Base64.strict_encode64(SecureRandom.random_bytes(32))

      expect { described_class.decrypt(ciphertext, key: wrong_key) }.to raise_error(OpenSSL::Cipher::CipherError)
    end
  end
end
