# frozen_string_literal: true

module Backend
  module Locales
    # Re-derives source_text/context from the current candidate list rather
    # than trusting whatever the client sent for each key - `keys` is just a
    # selection out of BulkTranslateCandidates, not the translation content
    # itself.
    class BulkTranslate < Backend::Operation
      def call(project:, locale:, keys:, unit_limit:)
        candidates = Backend::Locales::BulkTranslateCandidates.new.call(project: project, locale: locale).value!
        candidates_by_key = candidates[:candidates].to_h { |c| [c[:key], c] }

        items = step select_items(candidates_by_key, keys)

        step Backend::Translations::Create.new.call(
          project: project, target_locale_keys: [locale.key], items: items, unit_limit: unit_limit
        )
      end

      private

      def select_items(candidates_by_key, keys)
        items = keys.filter_map { |k| candidates_by_key[k] }
        return Failure([:validation, "None of the selected keys are valid candidates"]) if items.empty?

        Success(items)
      end
    end
  end
end
