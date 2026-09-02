# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::GlossaryTerms::Delete do
  describe '#call' do
    it 'deletes the glossary term' do
      term = create(:glossary_term)

      result = described_class.new.call(glossary_term: term)

      expect(result).to be_success
      expect(Backend::Models::GlossaryTerm[term.id]).to be_nil
    end
  end
end
