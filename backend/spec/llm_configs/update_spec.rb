# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::LlmConfigs::Update do
  describe '#call' do
    it 'sets monthly cost and token limits' do
      project = create(:project)

      result = described_class.new.call(
        project: project, updates: { monthly_cost_limit_usd: 50.0, monthly_token_limit: 1_000_000 }
      )

      config = result.value!
      expect(config.monthly_cost_limit_usd.to_f).to eq(50.0)
      expect(config.monthly_token_limit).to eq(1_000_000)
    end

    it 'leaves limits untouched when absent from updates' do
      project = create(:project)
      project.llm_config.update(monthly_token_limit: 100)

      described_class.new.call(project: project, updates: {})

      expect(project.llm_config.reload.monthly_token_limit).to eq(100)
    end

    it 'sets the active_llm_provider_config' do
      project = create(:project)
      provider_config = create(:llm_provider_config, project: project)

      result = described_class.new.call(
        project: project, updates: { active_llm_provider_config_id: provider_config.public_id }
      )

      expect(result.value!.active_llm_provider_config.id).to eq(provider_config.id)
    end

    it 'clears the active_llm_provider_config when set to nil' do
      project = create(:project, :with_llm_configured)

      result = described_class.new.call(project: project, updates: { active_llm_provider_config_id: nil })

      expect(result.value!.active_llm_provider_config).to be_nil
    end

    it "fails with :not_found when the given public_id doesn't belong to this project" do
      project = create(:project)
      other_config = create(:llm_provider_config)

      result = described_class.new.call(
        project: project, updates: { active_llm_provider_config_id: other_config.public_id }
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it "creates an llm_config if the project somehow doesn't have one yet" do
      project = create(:project)
      project.llm_config.destroy

      result = described_class.new.call(project: project.reload, updates: { monthly_token_limit: 500 })

      expect(result).to be_success
      expect(result.value!.monthly_token_limit).to eq(500)
    end

    it 'sets the alert email and threshold' do
      project = create(:project)

      result = described_class.new.call(
        project: project, updates: { alert_email: 'owner@example.com', alert_threshold_percent: 80 }
      )

      config = result.value!
      expect(config.alert_email).to eq('owner@example.com')
      expect(config.alert_threshold_percent).to eq(80)
    end

    it 'resets alert_sent_for_month when alert settings change' do
      project = create(:project)
      project.llm_config.update(
        alert_email: 'owner@example.com', alert_threshold_percent: 80, alert_sent_for_month: '2026-08'
      )

      described_class.new.call(project: project, updates: { alert_threshold_percent: 90 })

      expect(project.llm_config.reload.alert_sent_for_month).to be_nil
    end

    it "leaves alert_sent_for_month untouched when alert settings aren't in the update" do
      project = create(:project)
      project.llm_config.update(
        alert_email: 'owner@example.com', alert_threshold_percent: 80, alert_sent_for_month: '2026-08'
      )

      described_class.new.call(project: project, updates: { monthly_token_limit: 500 })

      expect(project.llm_config.reload.alert_sent_for_month).to eq('2026-08')
    end
  end
end
