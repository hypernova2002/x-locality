# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Locales::Delete do
  describe "#call" do
    it "deletes a custom locale" do
      locale = create(:locale, system: false)

      result = described_class.new.call(locale: locale)

      expect(result).to be_success
      expect(Backend::Models::Locale[locale.id]).to be_nil
    end

    it "fails with :forbidden for a system locale, and does not delete it" do
      locale = create(:locale, system: true)

      result = described_class.new.call(locale: locale)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
      expect(Backend::Models::Locale[locale.id]).not_to be_nil
    end
  end
end
