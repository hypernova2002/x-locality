# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::GlossaryTerms::Create do
  let(:project) { create(:project) }

  describe '#call' do
    it 'creates a glossary term with no target locale (applies to all locales)' do
      result = described_class.new.call(
        project: project, source_term: 'Acme Dashboard', source_language: 'en', target_term: 'Acme Dashboard'
      )

      term = result.value!
      expect(term.source_term).to eq('Acme Dashboard')
      expect(term.source_language).to eq('en')
      expect(term.target_term).to eq('Acme Dashboard')
      expect(term.target_locale_id).to be_nil
      expect(term.project_id).to eq(project.id)
    end

    it 'resolves target_locale_key to the locale' do
      locale_fr = create(:locale, project: project, key: 'fr')

      result = described_class.new.call(
        project: project, source_term: 'workspace', source_language: 'en', target_term: 'espace de travail',
        target_locale_key: 'fr'
      )

      expect(result.value!.target_locale_id).to eq(locale_fr.id)
    end

    it "fails with :validation for a target_locale_key that doesn't exist on the project" do
      result = described_class.new.call(
        project: project, source_term: 'workspace', source_language: 'en', target_term: 'espace de travail',
        target_locale_key: 'does-not-exist'
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it 'fails with :conflict for a duplicate source_term/source_language/target_locale' do
      create(:glossary_term, project: project, source_term: 'workspace', source_language: 'en')

      result = described_class.new.call(
        project: project, source_term: 'workspace', source_language: 'en', target_term: 'anything'
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end

    it 'allows the same source_term/source_language with a different target_locale' do
      locale_fr = create(:locale, project: project, key: 'fr')
      create(:glossary_term, project: project, source_term: 'workspace', source_language: 'en',
                             target_locale_id: nil)

      result = described_class.new.call(
        project: project, source_term: 'workspace', source_language: 'en', target_term: 'espace de travail',
        target_locale_key: 'fr'
      )

      expect(result).to be_success
      expect(result.value!.target_locale_id).to eq(locale_fr.id)
    end

    it 'allows the same source_term/source_language/target_locale on a different project' do
      other_project = create(:project)
      create(:glossary_term, project: other_project, source_term: 'workspace', source_language: 'en')

      result = described_class.new.call(
        project: project, source_term: 'workspace', source_language: 'en', target_term: 'anything'
      )

      expect(result).to be_success
    end
  end
end
