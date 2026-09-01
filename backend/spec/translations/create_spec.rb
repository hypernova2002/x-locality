# frozen_string_literal: true

require "spec_helper"

# FakeLlmAdapter lives in spec/support/fake_llm_adapter.rb - deliberately
# not an RSpec double (a `receive(:translate) do...end` block invoked later
# hits an autoload-timing issue), and stub_llm below deliberately takes no
# keyword params of its own (customize via the usage/raises writers
# instead) - a helper method with its own keyword params calling another
# keyword-arg constructor from inside its body trips a reproducible Ruby
# 4.0 argument-forwarding bug ("wrong number of arguments (given 0,
# expected 1)"), isolated separately, not worth fighting further here.

RSpec.describe Backend::Translations::Create do
  let(:project) { create(:project, :with_llm_configured) }
  let(:locale_fr) { create(:locale, project: project, key: "fr", target_language: "fr") }

  def stub_llm(results_by_key)
    adapter = FakeLlmAdapter.new(results_by_key: results_by_key)
    allow(Backend::Llm).to receive(:for_project).and_return(adapter)
    adapter
  end

  describe "#call" do
    it "translates items into the requested locale and persists them" do
      stub_llm("homepage-title" => "Bienvenue")

      result = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "homepage-title", source_text: "Welcome" }], unit_limit: 50
      )

      expect(result).to be_success
      body = result.value!
      expect(body).to eq([
        { key: "homepage-title", translations: [
          { locale: "fr", status: "completed", translated_text: "Bienvenue",
            detected_language: "en", cached: false }
        ] }
      ])

      persisted = project.translations_dataset.first(key: "homepage-title", locale_id: locale_fr.id)
      expect(persisted.translated_text).to eq("Bienvenue")
      expect(persisted.status).to eq("completed")
    end

    it "records the project's llm_provider at generation time, not just the model" do
      stub_llm("cta" => "Achetez")

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      persisted = project.translations_dataset.first(key: "cta", locale_id: locale_fr.id)
      expect(persisted.llm_provider).to eq(project.llm_config.active_llm_provider_config.provider)
      expect(persisted.model_used).to eq("claude-opus-5")
    end

    it "records an llm_usage_event with the token usage from the generation call" do
      adapter = stub_llm("cta" => "Achetez")
      adapter.usage = Backend::Llm::Usage.new(input_tokens: 42, output_tokens: 7)

      expect do
        described_class.new.call(
          project: project, target_locale_keys: [locale_fr.key],
          items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
        )
      end.to change { Backend::Models::LlmUsageEvent.count }.by(1)

      event = Backend::Models::LlmUsageEvent.last
      expect(event.project_id).to eq(project.id)
      expect(event.provider).to eq(project.llm_config.active_llm_provider_config.provider)
      expect(event.llm_model).to eq("claude-opus-5")
      expect(event.input_tokens).to eq(42)
      expect(event.output_tokens).to eq(7)
      expect(event.translation_count).to eq(1)
      expect(event.duration_ms).to be_a(Integer).and be >= 0
    end

    it "fails with :budget_exceeded once the monthly token limit is already met" do
      project.llm_config.update(monthly_token_limit: 100)
      Backend::Models::LlmUsageEvent.create(
        project_id: project.id, locale_id: locale_fr.id, provider: "anthropic", llm_model: "claude-opus-5",
        input_tokens: 80, output_tokens: 20, translation_count: 1, success: true, created_at: Time.now
      )
      adapter = stub_llm("cta" => "Achetez")

      result = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:budget_exceeded)
      expect(adapter.call_count).to eq(0)
    end

    it "fails with :budget_exceeded once the monthly cost limit is already met" do
      project.llm_config.update(monthly_cost_limit_usd: 1.0)
      Backend::Models::LlmUsageEvent.create(
        project_id: project.id, locale_id: locale_fr.id, provider: "anthropic", llm_model: "claude-opus-5",
        input_tokens: 1_000_000, output_tokens: 0, translation_count: 1, success: true, created_at: Time.now
      )
      stub_llm("cta" => "Achetez")

      result = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:budget_exceeded)
    end

    it "proceeds when usage is under both configured limits" do
      project.llm_config.update(monthly_token_limit: 1_000_000, monthly_cost_limit_usd: 100.0)
      stub_llm("cta" => "Achetez")

      result = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      expect(result).to be_success
    end

    it "enqueues a budget alert once usage crosses the configured threshold" do
      project.llm_config.update(
        monthly_token_limit: 100, alert_email: "owner@example.com", alert_threshold_percent: 80
      )
      Backend::Models::LlmUsageEvent.create(
        project_id: project.id, locale_id: locale_fr.id, provider: "anthropic", llm_model: "claude-opus-5",
        input_tokens: 80, output_tokens: 10, translation_count: 1, success: true, created_at: Time.now
      )
      stub_llm("cta" => "Achetez")

      expect(Backend::LlmConfigs::Jobs::SendBudgetAlertJob).to receive(:perform_async).with(project.id, 90, kind_of(Numeric))

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      expect(project.llm_config.reload.alert_sent_for_month).to eq(Date.today.strftime("%Y-%m"))
    end

    it "does not enqueue a second alert in the same month" do
      project.llm_config.update(
        monthly_token_limit: 100, alert_email: "owner@example.com", alert_threshold_percent: 80,
        alert_sent_for_month: Date.today.strftime("%Y-%m")
      )
      Backend::Models::LlmUsageEvent.create(
        project_id: project.id, locale_id: locale_fr.id, provider: "anthropic", llm_model: "claude-opus-5",
        input_tokens: 70, output_tokens: 10, translation_count: 1, success: true, created_at: Time.now
      )
      stub_llm("cta" => "Achetez")

      expect(Backend::LlmConfigs::Jobs::SendBudgetAlertJob).not_to receive(:perform_async)

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )
    end

    it "does not enqueue an alert when no alert_email is configured" do
      project.llm_config.update(monthly_token_limit: 100, alert_threshold_percent: 80)
      Backend::Models::LlmUsageEvent.create(
        project_id: project.id, locale_id: locale_fr.id, provider: "anthropic", llm_model: "claude-opus-5",
        input_tokens: 70, output_tokens: 10, translation_count: 1, success: true, created_at: Time.now
      )
      stub_llm("cta" => "Achetez")

      expect(Backend::LlmConfigs::Jobs::SendBudgetAlertJob).not_to receive(:perform_async)

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )
    end

    it "does not enqueue an alert while usage is still under the threshold" do
      project.llm_config.update(
        monthly_token_limit: 1_000, alert_email: "owner@example.com", alert_threshold_percent: 80
      )
      stub_llm("cta" => "Achetez")

      expect(Backend::LlmConfigs::Jobs::SendBudgetAlertJob).not_to receive(:perform_async)

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )
    end

    it "does not record usage or generate when every item is served from cache" do
      stub_llm("cta" => "Achetez")
      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      expect do
        described_class.new.call(
          project: project, target_locale_keys: [locale_fr.key],
          items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
        )
      end.not_to(change { Backend::Models::LlmUsageEvent.count })
    end

    it "bypasses the cache and re-generates when force is true" do
      adapter = stub_llm("cta" => "Achetez")
      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      body = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50, force: true
      ).value!

      expect(body.first[:translations].first[:cached]).to be(false)
      expect(adapter.call_count).to eq(2)
    end

    it "translates one item into multiple locales in a single call" do
      locale_de = create(:locale, project: project, key: "de", target_language: "de")
      stub_llm("greeting" => "Bonjour ou Hallo")

      body = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key, locale_de.key],
        items: [{ key: "greeting", source_text: "Hello" }], unit_limit: 50
      ).value!

      expect(body.first[:translations].map { |t| t[:locale] }).to contain_exactly("fr", "de")
    end

    it "persists context tags on the translation (regression: Sequel many_to_many has no bulk setter)" do
      tag = create(:context_tag, project: project, key: "marketing")
      stub_llm("cta" => "Achetez maintenant")

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy now", context: ["marketing"] }], unit_limit: 50
      )

      persisted = project.translations_dataset.first(key: "cta", locale_id: locale_fr.id)
      expect(persisted.context_tags.map(&:key)).to eq(["marketing"])
    end

    it "replaces context tags on re-translation rather than accumulating them" do
      tag_a = create(:context_tag, project: project, key: "tag-a")
      tag_b = create(:context_tag, project: project, key: "tag-b")
      stub_llm("cta" => "v1")

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy now", context: ["tag-a"] }], unit_limit: 50
      )

      stub_llm("cta" => "v2")
      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy now v2", context: ["tag-b"] }], unit_limit: 50
      )

      persisted = project.translations_dataset.first(key: "cta", locale_id: locale_fr.id)
      expect(persisted.context_tags.map(&:key)).to eq(["tag-b"])
    end

    it "records a translation_version on every generation" do
      stub_llm("cta" => "Achetez")

      expect do
        described_class.new.call(
          project: project, target_locale_keys: [locale_fr.key],
          items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
        )
      end.to change { Backend::Models::TranslationVersion.count }.by(1)
    end

    it "reuses a cached translation when the source text and context are unchanged" do
      adapter = stub_llm("cta" => "Achetez")

      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      body = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      ).value!

      expect(body.first[:translations].first[:cached]).to be(true)
      expect(adapter.call_count).to eq(1)
    end

    it "regenerates when the source text changes" do
      adapter = stub_llm("cta" => "Achetez")
      described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      stub_llm("cta" => "Achetez maintenant")
      body = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy now" }], unit_limit: 50
      ).value!

      expect(body.first[:translations].first[:cached]).to be(false)
      expect(body.first[:translations].first[:translated_text]).to eq("Achetez maintenant")
    end

    it "marks an item failed (without raising) when the LLM omits a requested key" do
      stub_llm({})

      body = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      ).value!

      expect(body.first[:translations].first).to include(status: "failed", translated_text: nil)
    end

    it "marks items failed (without raising) when the adapter raises" do
      adapter = stub_llm({})
      adapter.raises = "boom"

      body = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      ).value!

      expect(body.first[:translations].first).to include(status: "failed")
    end

    it "records a failed llm_usage_event (zeroed tokens) when the adapter raises" do
      adapter = stub_llm({})
      adapter.raises = "boom"

      expect do
        described_class.new.call(
          project: project, target_locale_keys: [locale_fr.key],
          items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
        )
      end.to change { Backend::Models::LlmUsageEvent.count }.by(1)

      event = Backend::Models::LlmUsageEvent.last
      expect(event.success).to be(false)
      expect(event.input_tokens).to eq(0)
      expect(event.output_tokens).to eq(0)
      expect(event.translation_count).to eq(1)
      expect(event.error_message).to eq("boom")
      expect(event.duration_ms).to be_a(Integer).and be >= 0
    end

    it "fails with :unconfigured when the project has no llm_api_key set" do
      unconfigured_project = create(:project)
      locale = create(:locale, project: unconfigured_project)

      result = described_class.new.call(
        project: unconfigured_project, target_locale_keys: [locale.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:unconfigured)
    end

    it "fails with :validation when the unit count exceeds the limit" do
      stub_llm("cta" => "Achetez")

      result = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 0
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "fails with :validation for an unknown target locale" do
      result = described_class.new.call(
        project: project, target_locale_keys: ["does-not-exist"],
        items: [{ key: "cta", source_text: "Buy" }], unit_limit: 50
      )

      expect(result).to be_failure
      expect(result.failure).to eq([:validation, "Unknown target locale(s): does-not-exist"])
    end

    it "fails with :validation for an unknown context tag" do
      result = described_class.new.call(
        project: project, target_locale_keys: [locale_fr.key],
        items: [{ key: "cta", source_text: "Buy", context: ["does-not-exist"] }], unit_limit: 50
      )

      expect(result).to be_failure
      expect(result.failure).to eq([:validation, "Unknown context tag(s): does-not-exist"])
    end
  end
end
