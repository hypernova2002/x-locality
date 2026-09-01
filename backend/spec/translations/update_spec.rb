# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Translations::Update do
  describe "#call" do
    it "updates the translated text" do
      translation = create(:translation, translated_text: "Bon retour", status: "completed", generated_by: "llm")
      user = create(:user)

      result = described_class.new.call(
        translation: translation, translated_text: "De retour !", changed_by_user: user
      )

      expect(result).to be_success
      expect(result.value!.translated_text).to eq("De retour !")
    end

    it "marks the translation as user-generated, not llm" do
      translation = create(:translation, generated_by: "llm")

      updated = described_class.new.call(
        translation: translation, translated_text: "Edited", changed_by_user: create(:user)
      ).value!

      expect(updated.generated_by).to eq("user")
    end

    it "sets status to completed even if it was previously failed" do
      translation = create(:translation, status: "failed", translated_text: nil)

      updated = described_class.new.call(
        translation: translation, translated_text: "Fixed manually", changed_by_user: create(:user)
      ).value!

      expect(updated.status).to eq("completed")
    end

    it "records a translation_version with the previous and new text" do
      translation = create(:translation, translated_text: "Old text")
      user = create(:user)

      described_class.new.call(translation: translation, translated_text: "New text", changed_by_user: user)

      version = translation.versions_dataset.order(:id).last
      expect(version.previous_value).to eq("Old text")
      expect(version.new_value).to eq("New text")
      expect(version.changed_by_type).to eq("user")
      expect(version.changed_by_user_id).to eq(user.id)
    end

    it "adds one version per edit rather than replacing history" do
      translation = create(:translation, translated_text: "v1")
      user = create(:user)

      expect do
        described_class.new.call(translation: translation, translated_text: "v2", changed_by_user: user)
        described_class.new.call(translation: translation, translated_text: "v3", changed_by_user: user)
      end.to change { translation.versions_dataset.count }.by(2)
    end
  end
end
