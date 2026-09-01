# frozen_string_literal: true

module Backend
  module Locales
    # Keys that exist somewhere in the project (any locale) but don't have a
    # completed translation for the given target locale yet - a missing
    # translation, a failed one, or one still pending. Used both to preview
    # a bulk-translate ("how many would this touch") and to build the item
    # list BulkTranslate actually generates from.
    class BulkTranslateCandidates < Backend::Operation
      def call(project:, locale:)
        source_by_key = project.translations_dataset
                               .exclude(source_text: nil)
                               .eager(:context_tags)
                               .order(:key, Sequel.desc(:updated_at))
                               .all
                               .group_by(&:key)
                               .transform_values(&:first)

        completed_keys = project.translations_dataset
                                .where(locale_id: locale.id, status: 'completed')
                                .select_map(:key)
                                .to_set

        candidates = source_by_key.except(*completed_keys).map do |key, row|
          {
            key: key,
            source_text: row.source_text,
            source_language: row.source_language || row.detected_language,
            context: row.context_tags.map(&:key)
          }
        end.sort_by { |c| c[:key] }

        { candidates: candidates, total: candidates.size }
      end
    end
  end
end
