# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Models::LlmConfig do
  describe 'associations' do
    it 'belongs to a project' do
      project = create(:project)

      expect(project.llm_config.project_id).to eq(project.id)
    end

    it 'has no active_llm_provider_config by default' do
      project = create(:project)

      expect(project.llm_config.active_llm_provider_config).to be_nil
    end

    it 'resolves the active_llm_provider_config once one is set' do
      project = create(:project, :with_llm_configured)
      provider_config = project.llm_provider_configs.first

      expect(project.llm_config.active_llm_provider_config.id).to eq(provider_config.id)
    end
  end
end
