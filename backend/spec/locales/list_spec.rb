# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Locales::List do
  let(:project) { create(:project) }

  describe '#call' do
    it 'returns every locale for the project, ordered by key' do
      create(:locale, project: project, key: 'fr')
      create(:locale, project: project, key: 'de')

      records = described_class.new.call(project: project).value!.all

      expect(records.map(&:key)).to eq(%w[de fr])
    end

    it "does not return another project's locales" do
      create(:locale, project: project, key: 'fr')
      other_project = create(:project)
      create(:locale, project: other_project, key: 'mine-not')

      records = described_class.new.call(project: project).value!.all

      expect(records.map(&:key)).to eq(['fr'])
    end

    it 'filters by key substring, case-insensitively' do
      create(:locale, project: project, key: 'fr-casual')
      create(:locale, project: project, key: 'de')

      records = described_class.new.call(project: project, key_filter: 'CASUAL').value!.all

      expect(records.map(&:key)).to eq(['fr-casual'])
    end

    it 'filters by target_language' do
      create(:locale, project: project, key: 'fr', target_language: 'fr')
      create(:locale, project: project, key: 'fr-ca', target_language: 'fr')
      create(:locale, project: project, key: 'de', target_language: 'de')

      records = described_class.new.call(project: project, language_filter: 'de').value!.all

      expect(records.map(&:key)).to eq(['de'])
    end

    it 'filters by system' do
      create(:locale, project: project, key: 'custom', system: false)
      create(:locale, project: project, key: 'seeded', system: true)

      records = described_class.new.call(project: project, system_filter: 'true').value!.all

      expect(records.map(&:key)).to eq(['seeded'])
    end

    it 'ignores an empty system_filter' do
      create(:locale, project: project, key: 'custom', system: false)
      create(:locale, project: project, key: 'seeded', system: true)

      records = described_class.new.call(project: project, system_filter: '').value!.all

      expect(records.map(&:key)).to eq(%w[custom seeded])
    end
  end
end
