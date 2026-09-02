# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::GlossaryTerms::List do
  let(:project) { create(:project) }

  describe '#call' do
    it 'returns every glossary term for the project, ordered by source_term' do
      create(:glossary_term, project: project, source_term: 'workspace')
      create(:glossary_term, project: project, source_term: 'dashboard')

      records = described_class.new.call(project: project).value!.all

      expect(records.map(&:source_term)).to eq(%w[dashboard workspace])
    end

    it "does not return another project's glossary terms" do
      create(:glossary_term, project: project, source_term: 'mine')
      other_project = create(:project)
      create(:glossary_term, project: other_project, source_term: 'theirs')

      records = described_class.new.call(project: project).value!.all

      expect(records.map(&:source_term)).to eq(['mine'])
    end

    it 'matches search on source_term' do
      create(:glossary_term, project: project, source_term: 'Acme Dashboard', target_term: 'Acme Dashboard')
      create(:glossary_term, project: project, source_term: 'workspace', target_term: 'espace de travail')

      records = described_class.new.call(project: project, search: 'dashboard').value!.all

      expect(records.map(&:source_term)).to eq(['Acme Dashboard'])
    end

    it 'matches search on target_term' do
      create(:glossary_term, project: project, source_term: 'workspace', target_term: 'espace de travail')

      records = described_class.new.call(project: project, search: 'espace').value!.all

      expect(records.map(&:source_term)).to eq(['workspace'])
    end

    it 'filters by source_language' do
      create(:glossary_term, project: project, source_term: 'a', source_language: 'en')
      create(:glossary_term, project: project, source_term: 'b', source_language: 'fr')

      records = described_class.new.call(project: project, source_language_filter: 'fr').value!.all

      expect(records.map(&:source_term)).to eq(['b'])
    end

    it 'filters by target_locale_key' do
      locale_fr = create(:locale, project: project, key: 'fr')
      create(:glossary_term, project: project, source_term: 'a', target_locale_id: locale_fr.id)
      create(:glossary_term, project: project, source_term: 'b', target_locale_id: nil)

      records = described_class.new.call(project: project, target_locale_key: 'fr').value!.all

      expect(records.map(&:source_term)).to eq(['a'])
    end

    it 'returns no results for an unknown target_locale_key' do
      create(:glossary_term, project: project, source_term: 'a')

      records = described_class.new.call(project: project, target_locale_key: 'does-not-exist').value!.all

      expect(records).to be_empty
    end
  end
end
