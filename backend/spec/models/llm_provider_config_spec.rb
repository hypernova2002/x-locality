# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Models::LlmProviderConfig do
  describe '#api_key= / #api_key' do
    it 'round-trips through encryption' do
      config = create(:llm_provider_config)

      config.api_key = 'sk-ant-super-secret'
      config.save

      expect(config.reload.api_key).to eq('sk-ant-super-secret')
    end

    it 'never stores the plaintext key in the ciphertext column' do
      config = create(:llm_provider_config)

      config.api_key = 'sk-ant-super-secret'
      config.save

      expect(config.api_key_ciphertext).not_to eq('sk-ant-super-secret')
    end

    it 'clears the key when set to nil' do
      config = create(:llm_provider_config)

      config.api_key = nil
      config.save

      expect(config.reload.api_key).to be_nil
    end

    it 'clears the key when set to an empty string' do
      config = create(:llm_provider_config)

      config.api_key = ''
      config.save

      expect(config.reload.api_key).to be_nil
    end
  end

  describe '#api_key_configured?' do
    it 'is false when no key has been set' do
      config = Backend::Models::LlmProviderConfig.create(project_id: create(:project).id, name: 'No key')

      expect(config.api_key_configured?).to be(false)
    end

    it 'is true once a key has been set' do
      expect(create(:llm_provider_config).api_key_configured?).to be(true)
    end
  end

  describe '#api_secret= / #api_secret' do
    it 'round-trips through encryption' do
      config = create(:llm_provider_config)

      config.api_secret = 'aws-super-secret'
      config.save

      expect(config.reload.api_secret).to eq('aws-super-secret')
    end

    it 'never stores the plaintext secret in the ciphertext column' do
      config = create(:llm_provider_config)

      config.api_secret = 'aws-super-secret'
      config.save

      expect(config.api_secret_ciphertext).not_to eq('aws-super-secret')
    end

    it 'clears the secret when set to nil' do
      config = create(:llm_provider_config)
      config.api_secret = 'aws-super-secret'
      config.save

      config.api_secret = nil
      config.save

      expect(config.reload.api_secret).to be_nil
    end
  end

  describe '#api_secret_configured?' do
    it 'is false when no secret has been set' do
      expect(create(:llm_provider_config).api_secret_configured?).to be(false)
    end

    it 'is true once a secret has been set' do
      config = create(:llm_provider_config)
      config.api_secret = 'aws-super-secret'
      config.save

      expect(config.api_secret_configured?).to be(true)
    end
  end
end
