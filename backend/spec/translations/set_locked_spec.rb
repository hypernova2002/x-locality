# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Translations::SetLocked do
  let(:project) { create(:project) }
  let(:locale_fr) { create(:locale, project: project, key: 'fr') }
  let(:locale_de) { create(:locale, project: project, key: 'de') }

  describe '#call' do
    it "locks every locale's translation for the given key" do
      create(:translation, project: project, locale: locale_fr, key: 'cta')
      create(:translation, project: project, locale: locale_de, key: 'cta')

      described_class.new.call(project: project, key: 'cta', locked: true)

      rows = project.translations_dataset.where(key: 'cta').all
      expect(rows.map(&:locked)).to all(be(true))
    end

    it 'unlocks when locked: false' do
      create(:translation, project: project, locale: locale_fr, key: 'cta', locked: true)

      described_class.new.call(project: project, key: 'cta', locked: false)

      expect(project.translations_dataset.first(key: 'cta').locked).to be(false)
    end

    it 'does not affect a different key' do
      create(:translation, project: project, locale: locale_fr, key: 'cta')
      create(:translation, project: project, locale: locale_fr, key: 'other')

      described_class.new.call(project: project, key: 'cta', locked: true)

      expect(project.translations_dataset.first(key: 'other').locked).to be(false)
    end

    it 'fails with :not_found for an unknown key' do
      result = described_class.new.call(project: project, key: 'missing', locked: true)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end
  end
end
