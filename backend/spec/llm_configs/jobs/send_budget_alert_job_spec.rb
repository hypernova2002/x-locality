# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::LlmConfigs::Jobs::SendBudgetAlertJob do
  describe '#perform' do
    it "delivers the budget alert mail for the project's llm_config" do
      project = create(:project)
      project.llm_config.update(alert_email: 'owner@example.com', alert_threshold_percent: 80)

      expect(Backend::LlmConfigs::BudgetAlertMailer).to receive(:deliver).with(
        project: project, config: project.llm_config, tokens_used: 90, cost_used: 1.5
      )

      described_class.new.perform(project.id, 90, 1.5)
    end

    it 'does nothing when the project no longer has an alert_email configured' do
      project = create(:project)

      expect(Backend::LlmConfigs::BudgetAlertMailer).not_to receive(:deliver)

      described_class.new.perform(project.id, 90, 1.5)
    end

    it 'does nothing when the project no longer exists' do
      expect(Backend::LlmConfigs::BudgetAlertMailer).not_to receive(:deliver)

      expect { described_class.new.perform(-1, 90, 1.5) }.not_to raise_error
    end
  end
end
