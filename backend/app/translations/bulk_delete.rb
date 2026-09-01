# frozen_string_literal: true

module Backend
  module Translations
    # Deletes translations by key (every locale at once). A key with any
    # locked translation is skipped entirely rather than partially deleted -
    # locking is a safety net against exactly this kind of accidental loss.
    class BulkDelete < Backend::Operation
      def call(project:, keys:)
        deleted = []
        skipped = []

        keys.each do |key|
          rows = project.translations_dataset.where(key: key).all

          if rows.empty?
            skipped << { key: key, reason: 'not_found' }
          elsif rows.any?(&:locked)
            skipped << { key: key, reason: 'locked' }
          else
            rows.each(&:destroy)
            deleted << key
          end
        end

        { deleted: deleted, skipped: skipped }
      end
    end
  end
end
