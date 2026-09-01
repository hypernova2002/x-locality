# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Translations::List do
  let(:project) { create(:project) }
  let(:locale_fr) { create(:locale, project: project, key: 'fr') }
  let(:locale_de) { create(:locale, project: project, key: 'de') }

  describe '#call' do
    it 'returns translations for the project' do
      create(:translation, project: project, locale: locale_fr, key: 'a')
      create(:translation, project: project, locale: locale_de, key: 'b')

      result = described_class.new.call(project: project)

      expect(result).to be_success
      expect(result.value![:records].size).to eq(2)
    end

    it "does not return another project's translations" do
      create(:translation, project: project, locale: locale_fr, key: 'mine')
      other_project = create(:project)
      other_locale = create(:locale, project: other_project)
      create(:translation, project: other_project, locale: other_locale, key: 'theirs')

      records = described_class.new.call(project: project).value![:records]

      expect(records.map(&:key)).to eq(['mine'])
    end

    it 'filters by locale_key' do
      create(:translation, project: project, locale: locale_fr, key: 'a')
      create(:translation, project: project, locale: locale_de, key: 'b')

      records = described_class.new.call(project: project, locale_key: 'fr').value![:records]

      expect(records.map(&:key)).to eq(['a'])
    end

    it 'fails with :validation for an unknown locale_key' do
      result = described_class.new.call(project: project, locale_key: 'does-not-exist')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it 'filters by a key substring' do
      create(:translation, project: project, locale: locale_fr, key: 'homepage-title')
      create(:translation, project: project, locale: locale_fr, key: 'button-post')

      records = described_class.new.call(project: project, key_filter: 'home').value![:records]

      expect(records.map(&:key)).to eq(['homepage-title'])
    end

    it 'signals has_more when more records exist than the limit' do
      3.times { |n| create(:translation, project: project, locale: locale_fr, key: "k#{n}") }

      data = described_class.new.call(project: project, limit: 2).value!

      expect(data[:records].size).to eq(2)
      expect(data[:has_more]).to be(true)
    end

    it 'does not signal has_more when all records fit within the limit' do
      3.times { |n| create(:translation, project: project, locale: locale_fr, key: "k#{n}") }

      data = described_class.new.call(project: project, limit: 10).value!

      expect(data[:records].size).to eq(3)
      expect(data[:has_more]).to be(false)
    end

    it 'paginates after a given id via the after cursor' do
      records = 3.times.map { |n| create(:translation, project: project, locale: locale_fr, key: "k#{n}") }

      page = described_class.new.call(project: project, after: records.first.id).value![:records]

      expect(page.map(&:id)).to eq(records[1..].map(&:id))
    end
  end
end
