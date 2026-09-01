# frozen_string_literal: true

module Backend
  module GlossaryTerms
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent.
      # `target_locale_key` is special-cased since the stored column is
      # target_locale_id, resolved from the given locale key here.
      def call(glossary_term:, updates:)
        attrs = updates.slice(:source_term, :source_language, :target_term)

        if updates.key?(:target_locale_key)
          attrs[:target_locale_id] = step resolve_target_locale(glossary_term.project, updates[:target_locale_key])
        end

        step check_available(glossary_term, attrs)

        glossary_term.update(attrs)
        glossary_term
      end

      private

      def resolve_target_locale(project, target_locale_key)
        return Success(nil) if target_locale_key.nil?

        locale = project.locales_dataset.first(key: target_locale_key)
        return Failure([:validation, "Unknown target locale '#{target_locale_key}'"]) unless locale

        Success(locale.id)
      end

      def check_available(glossary_term, attrs)
        source_term = attrs.fetch(:source_term, glossary_term.source_term)
        source_language = attrs.fetch(:source_language, glossary_term.source_language)
        target_locale_id = attrs.fetch(:target_locale_id, glossary_term.target_locale_id)

        existing = glossary_term.project.glossary_terms_dataset.first(
          source_term: source_term, source_language: source_language, target_locale_id: target_locale_id
        )
        if existing && existing.id != glossary_term.id
          return Failure([:conflict, "A glossary entry for this term/language/locale already exists"])
        end

        Success(true)
      end
    end
  end
end
