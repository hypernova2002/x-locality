# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Analytics::APIUsage do
  let(:account) { create(:account) }
  let(:project) { create(:project, account: account) }
  let(:api_key) { create(:api_key, project: project) }

  def log_request(project, api_key, status: 200, created_at: Time.now)
    Backend::Models::APIRequest.create(
      project_id: project.id, api_key_id: api_key.id,
      http_method: "POST", path: "/api/v1/translations", status: status, created_at: created_at
    )
  end

  describe "#call" do
    it "counts requests within the window, scoped to the project" do
      log_request(project, api_key)
      log_request(project, api_key)
      other_project = create(:project, account: account)
      log_request(other_project, create(:api_key, project: other_project))

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:total_requests]).to eq(2)
    end

    it "aggregates across every project on the account when project is nil" do
      other_project = create(:project, account: account)
      log_request(project, api_key)
      log_request(other_project, create(:api_key, project: other_project))

      data = described_class.new.call(account: account, project: nil).value!

      expect(data[:total_requests]).to eq(2)
    end

    it "excludes requests outside the day window" do
      log_request(project, api_key, created_at: Time.now - (40 * 24 * 60 * 60))

      data = described_class.new.call(account: account, project: project, days: 30).value!

      expect(data[:total_requests]).to eq(0)
    end

    it "sums translation_count from llm_usage_events in scope" do
      locale = create(:locale, project: project)
      Backend::Models::LlmUsageEvent.create(
        project_id: project.id, locale_id: locale.id, provider: "anthropic", llm_model: "claude-opus-5",
        input_tokens: 10, output_tokens: 5, translation_count: 3, created_at: Time.now
      )

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:total_translations]).to eq(3)
    end

    it "only counts successful llm_usage_events toward total_translations" do
      locale = create(:locale, project: project)
      Backend::Models::LlmUsageEvent.create(
        project_id: project.id, locale_id: locale.id, provider: "anthropic", llm_model: "claude-opus-5",
        input_tokens: 0, output_tokens: 0, translation_count: 5, success: false, created_at: Time.now
      )

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:total_translations]).to eq(0)
    end

    it "splits requests into successful and failed by status code" do
      log_request(project, api_key, status: 200)
      log_request(project, api_key, status: 201)
      log_request(project, api_key, status: 422)
      log_request(project, api_key, status: 500)

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:successful_requests]).to eq(2)
      expect(data[:failed_requests]).to eq(2)
    end

    it "counts completed and failed translations touched within the window" do
      locale = create(:locale, project: project)
      create(:translation, project: project, locale: locale, key: "a", status: "completed")
      create(:translation, project: project, locale: locale, key: "b", status: "failed")
      create(:translation, project: project, locale: locale, key: "c", status: "pending")

      data = described_class.new.call(account: account, project: project).value!

      expect(data[:translations_completed]).to eq(1)
      expect(data[:translations_failed]).to eq(1)
    end
  end
end
