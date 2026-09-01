# frozen_string_literal: true

module Backend
  module Translations
    # Force-regenerates every locale of each given key in one call per key -
    # reuses Translations::Create (force: true) so caching/versioning/usage
    # tracking all behave exactly as a single-row Regenerate would.
    class BulkRegenerate < Backend::Operation
      def call(project:, keys:, unit_limit: 200)
        regenerated = []
        failed = []

        keys.each do |key|
          rows = project.translations_dataset.where(key: key).all

          if rows.empty?
            failed << { key: key, reason: 'not_found' }
            next
          end

          locales = project.locales_dataset.where(id: rows.map(&:locale_id).uniq).all
          source = rows.first

          result = Backend::Translations::Create.new.call(
            project: project,
            target_locale_keys: locales.map(&:key),
            items: [{
              key: key,
              source_text: source.source_text,
              source_language: source.source_language,
              context: source.context_tags.map(&:key)
            }],
            unit_limit: unit_limit,
            force: true
          )

          case result
          in Success(_body)
            regenerated << key
          in Failure[_code, detail]
            failed << { key: key, reason: detail }
          end
        end

        { regenerated: regenerated, failed: failed }
      end
    end
  end
end
