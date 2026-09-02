# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::GlossaryTerms::Update do
  let(:project) { create(:project) }

  describe '#call' do
    it 'updates target_term' do
      term = create(:glossary_term, project: project, target_term: 'old')

      result = described_class.new.call(glossary_term: term, updates: { target_term: 'new' })

      expect(result.value!.target_term).to eq('new')
    end

    it 'resolves target_locale_key to target_locale_id' do
      locale_fr = create(:locale, project: project, key: 'fr')
      term = create(:glossary_term, project: project, target_locale_id: nil)

      result = described_class.new.call(glossary_term: term, updates: { target_locale_key: 'fr' })

      expect(result.value!.target_locale_id).to eq(locale_fr.id)
    end

    it 'clears target_locale_id when target_locale_key is explicitly nil' do
      locale_fr = create(:locale, project: project, key: 'fr')
      term = create(:glossary_term, project: project, target_locale_id: locale_fr.id)

      result = described_class.new.call(glossary_term: term, updates: { target_locale_key: nil })

      expect(result.value!.target_locale_id).to be_nil
    end

    it "fails with :validation for a target_locale_key that doesn't exist on the project" do
      term = create(:glossary_term, project: project)

      result = described_class.new.call(glossary_term: term, updates: { target_locale_key: 'does-not-exist' })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it 'fails with :conflict when the update collides with another term' do
      create(:glossary_term, project: project, source_term: 'brand', source_language: 'en')
      term = create(:glossary_term, project: project, source_term: 'workspace', source_language: 'en')

      result = described_class.new.call(glossary_term: term, updates: { source_term: 'brand' })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
      expect(term.reload.source_term).to eq('workspace')
    end

    it 'allows updating a term to its own current values without conflict' do
      term = create(:glossary_term, project: project, source_term: 'workspace', source_language: 'en')

      result = described_class.new.call(
        glossary_term: term, updates: { source_term: 'workspace', target_term: 'updated' }
      )

      expect(result).to be_success
    end
  end
end
