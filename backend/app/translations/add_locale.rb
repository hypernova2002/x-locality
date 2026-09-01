# frozen_string_literal: true

module Backend
  module Translations
    # Generates a translation for an existing key in a locale that doesn't
    # have one yet, reusing whatever source_text/context this key already
    # has in another locale - the same "source of truth" lookup
    # Locales::BulkTranslateCandidates uses, just for one key instead of a
    # whole locale's worth.
    class AddLocale < Backend::Operation
      def call(project:, key:, locale_key:)
        source = step find_source(project, key)
        locale = step find_locale(project, locale_key)
        step check_not_already_present(project, key, locale)

        item = {
          key: key,
          source_text: source.source_text,
          source_language: source.source_language || source.detected_language,
          context: source.context_tags.map(&:key)
        }

        step Backend::Translations::Create.new.call(
          project: project, target_locale_keys: [locale.key], items: [item], unit_limit: 1
        )
      end

      private

      def find_source(project, key)
        source = project.translations_dataset.where(key: key).exclude(source_text: nil).first
        return Failure([:not_found, "No existing translation found for key '#{key}'"]) unless source

        Success(source)
      end

      def find_locale(project, locale_key)
        locale = project.locales_dataset.first(key: locale_key)
        return Failure([:validation, "Unknown locale '#{locale_key}'"]) unless locale

        Success(locale)
      end

      def check_not_already_present(project, key, locale)
        existing = project.translations_dataset.first(key: key, locale_id: locale.id)
        return Failure([:conflict, "This key already has a translation for that locale"]) if existing

        Success(true)
      end
    end
  end
end
