# frozen_string_literal: true

module Backend
  module GlossaryTerms
    class Delete < Backend::Operation
      def call(glossary_term:)
        glossary_term.destroy
        glossary_term
      end
    end
  end
end
