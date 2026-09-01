# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::LlmProviderConfigs::Delete do
  describe "#call" do
    it "destroys the config" do
      config = create(:llm_provider_config)

      described_class.new.call(config: config)

      expect(Backend::Models::LlmProviderConfig[config.id]).to be_nil
    end

    it "clears the project's active_llm_provider_config_id when deleting the active config" do
      project = create(:project, :with_llm_configured)
      active_config = project.llm_config.active_llm_provider_config

      described_class.new.call(config: active_config)

      expect(project.llm_config.reload.active_llm_provider_config_id).to be_nil
    end
  end
end
