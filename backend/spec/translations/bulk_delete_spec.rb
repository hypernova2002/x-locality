# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Translations::BulkDelete do
  let(:project) { create(:project) }
  let(:locale_fr) { create(:locale, project: project, key: 'fr') }
  let(:locale_de) { create(:locale, project: project, key: 'de') }

  describe '#call' do
    it "deletes every locale's translation for each requested key" do
      create(:translation, project: project, locale: locale_fr, key: 'a')
      create(:translation, project: project, locale: locale_de, key: 'a')
      create(:translation, project: project, locale: locale_fr, key: 'b')

      result = described_class.new.call(project: project, keys: %w[a b]).value!

      expect(result[:deleted]).to contain_exactly('a', 'b')
      expect(project.translations_dataset.count).to eq(0)
    end

    it 'skips a key that has any locked translation, deleting nothing for it' do
      create(:translation, project: project, locale: locale_fr, key: 'a', locked: true)
      create(:translation, project: project, locale: locale_de, key: 'a', locked: false)
      create(:translation, project: project, locale: locale_fr, key: 'b')

      result = described_class.new.call(project: project, keys: %w[a b]).value!

      expect(result[:deleted]).to eq(['b'])
      expect(result[:skipped]).to eq([{ key: 'a', reason: 'locked' }])
      expect(project.translations_dataset.where(key: 'a').count).to eq(2)
    end

    it 'skips an unknown key' do
      result = described_class.new.call(project: project, keys: ['missing']).value!

      expect(result[:deleted]).to eq([])
      expect(result[:skipped]).to eq([{ key: 'missing', reason: 'not_found' }])
    end

    it "does not delete another project's translations" do
      other_project = create(:project)
      other_locale = create(:locale, project: other_project, key: 'fr')
      create(:translation, project: other_project, locale: other_locale, key: 'a')

      described_class.new.call(project: project, keys: ['a'])

      expect(other_project.translations_dataset.count).to eq(1)
    end
  end
end
