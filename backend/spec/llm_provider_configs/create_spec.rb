# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::LlmProviderConfigs::Create do
  describe '#call' do
    it 'creates a named config with the given provider' do
      project = create(:project)

      config = described_class.new.call(project: project, name: 'Prod key', provider: 'anthropic').value!

      expect(config.project_id).to eq(project.id)
      expect(config.name).to eq('Prod key')
      expect(config.provider).to eq('anthropic')
      expect(config.llm_model).to be_nil
      expect(config.api_key_configured?).to be(false)
    end

    it 'sets description, model and api_key when given' do
      project = create(:project)

      config = described_class.new.call(
        project: project, name: 'Backup key', provider: 'gemini',
        description: 'Fallback for when the primary key is rate-limited',
        model: 'gemini-3.5-flash', api_key: 'sk-gemini-secret'
      ).value!

      expect(config.description).to eq('Fallback for when the primary key is rate-limited')
      expect(config.llm_model).to eq('gemini-3.5-flash')
      expect(config.api_key).to eq('sk-gemini-secret')
    end

    it 'allows two configs with the same provider/model but different keys' do
      project = create(:project)
      described_class.new.call(project: project, name: 'Key A', provider: 'anthropic', model: 'claude-opus-5')

      config_b = described_class.new.call(
        project: project, name: 'Key B', provider: 'anthropic', model: 'claude-opus-5'
      ).value!

      expect(project.llm_provider_configs_dataset.count).to eq(2)
      expect(config_b.name).to eq('Key B')
    end
  end
end
