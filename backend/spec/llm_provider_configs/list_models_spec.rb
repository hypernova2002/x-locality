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
        .with(provider: 'anthropic', api_key: 'sk-ant-secret')
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
  end
end
