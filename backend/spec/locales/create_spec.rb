# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Locales::Create do
  describe "#call" do
    it "creates a non-system locale" do
      project = create(:project)

      result = described_class.new.call(project: project, key: "fr-casual", target_language: "fr")

      expect(result).to be_success
      locale = result.value!
      expect(locale.system).to be(false)
      expect(locale.key).to eq("fr-casual")
    end

    it "accepts optional style_tone_text and general_description" do
      locale = described_class.new.call(
        project: create(:project), key: "fr-casual", target_language: "fr",
        style_tone_text: "Casual", general_description: "For social posts"
      ).value!

      expect(locale.style_tone_text).to eq("Casual")
      expect(locale.general_description).to eq("For social posts")
    end

    it "fails with :conflict when the key already exists on the project" do
      project = create(:project)
      create(:locale, project: project, key: "fr-casual")

      result = described_class.new.call(project: project, key: "fr-casual", target_language: "fr")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end

    it "allows the same key on a different project" do
      create(:locale, project: create(:project), key: "fr-casual")

      result = described_class.new.call(project: create(:project), key: "fr-casual", target_language: "fr")

      expect(result).to be_success
    end
  end
end
