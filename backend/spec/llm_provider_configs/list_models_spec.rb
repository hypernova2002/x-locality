# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::LlmProviderConfigs::ListModels do
  describe '#call' do
    it 'fails with :unconfigured when provider or api_key is blank' do
      result = described_class.new.call(provider: 'anthropic', api_key: '')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:unconfigured)
    end

    it 'returns the models from Backend::Llm.list_models for the given provider/key' do
      models = [{ id: 'claude-opus-5', name: 'Claude Opus 5' }]
      allow(Backend::Llm).to receive(:list_models)
        .with(provider: 'anthropic', api_key: 'sk-ant-secret', api_secret: nil, region: nil)
        .and_return(models)

      result = described_class.new.call(provider: 'anthropic', api_key: 'sk-ant-secret')

      expect(result.value!).to eq(models)
    end

    it 'fails with :unconfigured (not raising) when the provider call errors' do
      allow(Backend::Llm).to receive(:list_models).and_raise('invalid api key')

      result = described_class.new.call(provider: 'anthropic', api_key: 'sk-ant-bad')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:unconfigured)
    end

    it 'fails with :unconfigured when an AWS provider is missing the secret key or region' do
      result = described_class.new.call(provider: 'bedrock', api_key: 'AKIAEXAMPLE')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:unconfigured)
    end

    it 'passes api_secret/region through for AWS providers' do
      models = [{ id: 'anthropic.claude-sonnet-5', name: 'Anthropic Claude Sonnet 5' }]
      allow(Backend::Llm).to receive(:list_models)
        .with(provider: 'bedrock', api_key: 'AKIAEXAMPLE', api_secret: 'secret', region: 'us-east-1')
        .and_return(models)

      result = described_class.new.call(provider: 'bedrock', api_key: 'AKIAEXAMPLE', api_secret: 'secret',
                                        region: 'us-east-1')

      expect(result.value!).to eq(models)
    end
  end
end
