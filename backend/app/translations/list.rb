# frozen_string_literal: true

module Backend
  module Translations
    class List < Backend::Operation
      def call(project:, locale_key: nil, key_filter: nil, after: nil, limit: 50)
        dataset = project.translations_dataset.order(:id).limit(limit + 1)
        dataset = dataset.where { id > after } if after

        dataset = step scope_to_locale(project, dataset, locale_key) if locale_key

        dataset = dataset.where(Sequel.ilike(:key, "%#{key_filter}%")) if key_filter

        records = dataset.all
        has_more = records.size > limit

        { records: records.first(limit), has_more: has_more }
      end

      private

      def scope_to_locale(project, dataset, locale_key)
        locale = project.locales_dataset.first(key: locale_key)
        return Failure([:validation, "Unknown locale: #{locale_key}"]) unless locale

        Success(dataset.where(locale_id: locale.id))
      end
    end
  end
end
