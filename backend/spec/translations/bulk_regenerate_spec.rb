# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Translations::BulkRegenerate do
  let(:project) { create(:project, :with_llm_configured) }
  let(:locale_fr) { create(:locale, project: project, key: "fr", target_language: "fr") }
  let(:locale_de) { create(:locale, project: project, key: "de", target_language: "de") }

  def stub_llm(results_by_key)
    adapter = FakeLlmAdapter.new(results_by_key: results_by_key)
    allow(Backend::Llm).to receive(:for_project).and_return(adapter)
    adapter
  end

  describe "#call" do
    it "regenerates every locale of each given key, bypassing the cache" do
      create(:translation, project: project, locale: locale_fr, key: "cta", source_text: "Buy now",
        translated_text: "old fr", status: "completed")
      create(:translation, project: project, locale: locale_de, key: "cta", source_text: "Buy now",
        translated_text: "old de", status: "completed")
      stub_llm("cta" => "new translation")

      result = described_class.new.call(project: project, keys: ["cta"]).value!

      expect(result[:regenerated]).to eq(["cta"])
      fr_row = project.translations_dataset.first(key: "cta", locale_id: locale_fr.id)
      de_row = project.translations_dataset.first(key: "cta", locale_id: locale_de.id)
      expect(fr_row.translated_text).to eq("new translation")
      expect(de_row.translated_text).to eq("new translation")
    end

    it "reports an unknown key as failed with not_found" do
      result = described_class.new.call(project: project, keys: ["missing"]).value!

      expect(result[:regenerated]).to eq([])
      expect(result[:failed]).to eq([{ key: "missing", reason: "not_found" }])
    end

    it "processes multiple keys independently, one failure not blocking the rest" do
      create(:translation, project: project, locale: locale_fr, key: "a", source_text: "Hello")
      create(:translation, project: project, locale: locale_fr, key: "b", source_text: "Bye")
      stub_llm("a" => "Bonjour", "b" => "Au revoir")

      result = described_class.new.call(project: project, keys: %w[a b missing]).value!

      expect(result[:regenerated]).to contain_exactly("a", "b")
      expect(result[:failed]).to eq([{ key: "missing", reason: "not_found" }])
    end
  end
end
