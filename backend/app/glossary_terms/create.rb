# frozen_string_literal: true

module Backend
  module GlossaryTerms
    class Create < Backend::Operation
      def call(project:, source_term:, source_language:, target_term:, target_locale_key: nil)
        target_locale_id = step resolve_target_locale(project, target_locale_key)
        step check_available(project, source_term, source_language, target_locale_id)

        Backend::Models::GlossaryTerm.create(
          project_id: project.id, source_term: source_term, source_language: source_language,
          target_term: target_term, target_locale_id: target_locale_id
        )
      end

      private

      # nil target_locale_key means the mapping applies regardless of
      # target locale (e.g. a brand name that should never be translated).
      def resolve_target_locale(project, target_locale_key)
        return Success(nil) if target_locale_key.nil?

        locale = project.locales_dataset.first(key: target_locale_key)
        return Failure([:validation, "Unknown target locale '#{target_locale_key}'"]) unless locale

        Success(locale.id)
      end

      def check_available(project, source_term, source_language, target_locale_id)
        existing = project.glossary_terms_dataset.first(
          source_term: source_term, source_language: source_language, target_locale_id: target_locale_id
        )
        return Failure([:conflict, 'A glossary entry for this term/language/locale already exists']) if existing

        Success(true)
      end
    end
  end
end
