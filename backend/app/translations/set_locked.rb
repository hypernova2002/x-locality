# frozen_string_literal: true

module Backend
  module Translations
    # Locking is whole-key: every locale's translation for a key is
    # locked/unlocked together, matching the grouped admin list where a key
    # is the unit a user selects.
    class SetLocked < Backend::Operation
      def call(project:, key:, locked:)
        rows = project.translations_dataset.where(key: key).all
        step check_found(rows, key)

        rows.each { |row| row.update(locked: locked) }
        key
      end

      private

      def check_found(rows, key)
        return Failure([:not_found, "No translations found for key '#{key}'"]) if rows.empty?

        Success(true)
      end
    end
  end
end
