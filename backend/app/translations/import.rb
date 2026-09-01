# frozen_string_literal: true

require "csv"
require "json"
require "zlib"
require "stringio"
require "base64"

module Backend
  module Translations
    # Upserts translations from a long-format CSV/JSON export (see Export).
    # A row for a locked translation is skipped rather than overwritten -
    # same safety net bulk_delete uses. Imported rows are always attributed
    # to generated_by: "user" - this is a human-driven bulk edit, not an LLM
    # generation, and doesn't record per-row version history (the volume a
    # bulk import can carry isn't worth a version row per translation).
    class Import < Backend::Operation
      def call(project:, format:, content_base64:, compressed:)
        raw = step decode(content_base64, compressed)
        rows = step parse(raw, format)

        locales_by_key = project.locales_dataset.all.to_h { |l| [l.key, l] }
        created = 0
        updated = 0
        skipped = []

        rows.each do |row|
          key = row[:key].to_s.strip
          locale_key = row[:locale].to_s.strip

          if key.empty? || locale_key.empty?
            skipped << { key: key, locale: locale_key, reason: "missing_key_or_locale" }
            next
          end

          locale = locales_by_key[locale_key]
          unless locale
            skipped << { key: key, locale: locale_key, reason: "unknown_locale" }
            next
          end

          source_text = row[:source_text].to_s
          if source_text.empty?
            skipped << { key: key, locale: locale_key, reason: "missing_source_text" }
            next
          end

          existing = project.translations_dataset.first(key: key, locale_id: locale.id)
          if existing&.locked
            skipped << { key: key, locale: locale_key, reason: "locked" }
            next
          end

          translated_text = row[:translated_text].to_s.empty? ? nil : row[:translated_text].to_s
          status = row[:status].to_s.empty? ? (translated_text ? "completed" : "pending") : row[:status].to_s
          source_language = row[:source_language].to_s.empty? ? nil : row[:source_language].to_s

          attrs = {
            source_text: source_text, source_language: source_language,
            translated_text: translated_text, status: status, generated_by: "user"
          }

          if existing
            existing.update(attrs)
            updated += 1
          else
            Backend::Models::Translation.create(attrs.merge(project_id: project.id, locale_id: locale.id, key: key))
            created += 1
          end
        end

        { created: created, updated: updated, skipped: skipped }
      end

      private

      def decode(content_base64, compressed)
        raw = Base64.strict_decode64(content_base64)
        decoded = compressed ? Zlib::GzipReader.new(StringIO.new(raw)).read : raw
        Success(decoded)
      rescue StandardError => e
        Failure([:validation, "Could not decode uploaded file: #{e.message}"])
      end

      def parse(raw, format)
        rows = case format
               when "json" then JSON.parse(raw, symbolize_names: true)
               when "csv" then CSV.parse(raw, headers: true, header_converters: :symbol).map(&:to_h)
               end
        Success(rows)
      rescue StandardError => e
        Failure([:validation, "Could not parse file: #{e.message}"])
      end
    end
  end
end
