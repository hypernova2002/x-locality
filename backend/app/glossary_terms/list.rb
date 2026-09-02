# frozen_string_literal: true

module Backend
  module GlossaryTerms
    class List < Backend::Operation
      def call(project:, search: nil, source_language_filter: nil, target_locale_key: nil)
        dataset = project.glossary_terms_dataset.order(:source_term).eager(:target_locale)
        dataset = apply_search(dataset, search)
        dataset = dataset.where(source_language: source_language_filter) if present?(source_language_filter)
        dataset = apply_target_locale(dataset, project, target_locale_key) if present?(target_locale_key)
        dataset
      end

      private

      def present?(value)
        !value.nil? && !value.empty?
      end

      def apply_search(dataset, search)
        return dataset unless present?(search)

        dataset.where(Sequel.ilike(:source_term, "%#{search}%") | Sequel.ilike(:target_term, "%#{search}%"))
      end

      # No match means "filter to a locale that doesn't exist" - an empty
      # result is the right answer, not an error, for a search filter. `id`
      # is a non-nullable primary key, so this condition never matches.
      def apply_target_locale(dataset, project, target_locale_key)
        locale = project.locales_dataset.first(key: target_locale_key)
        return dataset.where(id: nil) unless locale

        dataset.where(target_locale_id: locale.id)
      end
    end
  end
end
