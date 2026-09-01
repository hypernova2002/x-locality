# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Analytics::LlmUsage do
  let(:account) { create(:account) }
  let(:project) { create(:project, account: account) }
  let(:locale) { create(:locale, project: project) }

  def log_event(project, locale, provider:, model:, input_tokens:, output_tokens:, success: true,
                error_message: nil, created_at: Time.now, duration_ms: nil)
    Backend::Models::LlmUsageEvent.create(
      project_id: project.id, locale_id: locale.id, provider: provider, llm_model: model,
      input_tokens: input_tokens, output_tokens: output_tokens, translation_count: 1,
      success: success, error_message: error_message, created_at: created_at, duration_ms: duration_ms
    )
  end

  describe '#call' do
    it 'sums input/output tokens within the window, scoped to the project' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 100, output_tokens: 20)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 50, output_tokens: 10)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:total_input_tokens]).to eq(150)
      expect(data[:total_output_tokens]).to eq(30)
    end

    it 'calculates cost using the pricing table for a known model' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 1_000_000,
                                 output_tokens: 1_000_000)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:total_cost]).to eq(15.0 + 75.0)
    end

    it 'still returns token counts when the model has no known pricing' do
      log_event(project, locale, provider: 'custom', model: 'unlisted-model', input_tokens: 100, output_tokens: 20)

      data = described_class.new.call(account: account, project: project).value!

      row = data[:by_provider_model].first
      expect(row[:input_tokens]).to eq(100)
      expect(row[:cost]).to be_nil
    end

    it 'breaks down by provider and model' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 100, output_tokens: 20)
      log_event(project, locale, provider: 'gemini', model: 'gemini-3.5-flash', input_tokens: 200, output_tokens: 40)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:by_provider_model].map { |r| r[:provider] }).to contain_exactly('anthropic', 'gemini')
    end

    it 'aggregates across every project on the account when project is nil' do
      other_project = create(:project, account: account)
      other_locale = create(:locale, project: other_project)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 100, output_tokens: 20)
      log_event(other_project, other_locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 100,
                                             output_tokens: 20)

      data = described_class.new.call(account: account, project: nil).value!

      expect(data[:total_input_tokens]).to eq(200)
    end

    it 'counts successful and failed calls separately, and excludes failed calls from token/cost totals' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 100, output_tokens: 20)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 0, output_tokens: 0,
                                 success: false)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 0, output_tokens: 0,
                                 success: false)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:successful_calls]).to eq(1)
      expect(data[:failed_calls]).to eq(2)
      expect(data[:total_input_tokens]).to eq(100)
    end

    it 'includes failed_calls per day and per provider/model' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 100, output_tokens: 20)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 0, output_tokens: 0,
                                 success: false)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:by_day].first[:failed_calls]).to eq(1)
      row = data[:by_provider_model].first
      expect(row[:successful_calls]).to eq(1)
      expect(row[:failed_calls]).to eq(1)
    end

    it 'returns the most recent failures with their error messages, newest first' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 0, output_tokens: 0,
                                 success: false, error_message: 'rate limited', created_at: Time.now - 60)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 0, output_tokens: 0,
                                 success: false, error_message: 'timeout', created_at: Time.now)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 10, output_tokens: 5)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:recent_failures].map { |f| f[:error_message] }).to eq(['timeout', 'rate limited'])
    end

    it 'averages latency across successful calls, ignoring events with no duration recorded' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 10, output_tokens: 5,
                                 duration_ms: 200)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 10, output_tokens: 5,
                                 duration_ms: 400)
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 10, output_tokens: 5,
                                 duration_ms: nil)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:avg_latency_ms]).to eq(300)
      expect(data[:by_provider_model].first[:avg_latency_ms]).to eq(300)
    end

    it 'is nil when no events have a recorded duration' do
      log_event(project, locale, provider: 'anthropic', model: 'claude-opus-5', input_tokens: 10, output_tokens: 5)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:avg_latency_ms]).to be_nil
    end
  end
end
