# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::LlmProviderConfigs::Update do
  describe '#call' do
    it 'updates only the keys present in updates' do
      config = create(:llm_provider_config, name: 'Old name', provider: 'anthropic')

      updated = described_class.new.call(config: config, updates: { name: 'New name' }).value!

      expect(updated.name).to eq('New name')
      expect(updated.provider).to eq('anthropic')
    end

    it 'updates the model' do
      config = create(:llm_provider_config)

      described_class.new.call(config: config, updates: { model: 'gemini-3.5-flash' })

      expect(config.reload.llm_model).to eq('gemini-3.5-flash')
    end

    it 'sets the api key' do
      config = create(:llm_provider_config)

      described_class.new.call(config: config, updates: { api_key: 'sk-ant-new-secret' })

      expect(config.reload.api_key).to eq('sk-ant-new-secret')
    end

    it 'leaves the api key untouched when absent from updates' do
      config = create(:llm_provider_config)
      original_key = config.api_key

      described_class.new.call(config: config, updates: { name: 'Renamed' })

      expect(config.reload.api_key).to eq(original_key)
    end

    it 'clears the api key when explicitly set to nil' do
      config = create(:llm_provider_config)

      described_class.new.call(config: config, updates: { api_key: nil })

      expect(config.reload.api_key).to be_nil
    end

    it 'sets api_secret and region' do
      config = create(:llm_provider_config, provider: 'bedrock')

      described_class.new.call(config: config, updates: { api_secret: 'aws-secret', region: 'us-east-1' })

      expect(config.reload.api_secret).to eq('aws-secret')
      expect(config.region).to eq('us-east-1')
    end

    it 'leaves api_secret untouched when absent from updates' do
      config = create(:llm_provider_config, provider: 'bedrock')
      described_class.new.call(config: config, updates: { api_secret: 'aws-secret' })

      described_class.new.call(config: config, updates: { name: 'Renamed' })

      expect(config.reload.api_secret).to eq('aws-secret')
    end
  end
end
