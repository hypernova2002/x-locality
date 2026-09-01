# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::LlmConfigs::SendTestAlert do
  describe '#call' do
    it 'fails with :validation when no alert_email is configured' do
      project = create(:project)

      result = described_class.new.call(project: project)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it 'delivers a test email via BudgetAlertMailer' do
      project = create(:project)
      project.llm_config.update(alert_email: 'owner@example.com', alert_threshold_percent: 80)

      expect(Backend::LlmConfigs::BudgetAlertMailer).to receive(:deliver_test).with(
        project: project, config: project.llm_config
      )

      result = described_class.new.call(project: project)

      expect(result).to be_success
    end

    it 'fails with :validation when delivery raises' do
      project = create(:project)
      project.llm_config.update(alert_email: 'owner@example.com')
      allow(Backend::LlmConfigs::BudgetAlertMailer).to receive(:deliver_test).and_raise('smtp down')

      result = described_class.new.call(project: project)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end
  end
end
