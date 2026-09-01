# frozen_string_literal: true

require 'csv'
require 'json'
require 'zlib'
require 'stringio'
require 'base64'

module Backend
  module GlossaryTerms
    # Upserts glossary terms from a long-format CSV/JSON export (see
    # Export), matching existing rows on (source_term, source_language,
    # target_locale). A blank target_locale means the mapping applies
    # regardless of target locale.
    class Import < Backend::Operation
      def call(project:, format:, content_base64:, compressed:)
        raw = step decode(content_base64, compressed)
        rows = step parse(raw, format)

        locales_by_key = project.locales_dataset.all.to_h { |l| [l.key, l] }
        created = 0
        updated = 0
        skipped = []

        rows.each do |row|
          source_term = row[:source_term].to_s.strip
          source_language = row[:source_language].to_s.strip
          target_term = row[:target_term].to_s

          if source_term.empty? || source_language.empty? || target_term.empty?
            skipped << { key: source_term, reason: 'missing_required_field' }
            next
          end

          target_locale_key = row[:target_locale].to_s.strip
          target_locale_id = nil
          unless target_locale_key.empty?
            locale = locales_by_key[target_locale_key]
            unless locale
              skipped << { key: source_term, reason: 'unknown_target_locale' }
              next
            end
            target_locale_id = locale.id
          end

          existing = project.glossary_terms_dataset.first(
            source_term: source_term, source_language: source_language, target_locale_id: target_locale_id
          )

          if existing
            existing.update(target_term: target_term)
            updated += 1
          else
            Backend::Models::GlossaryTerm.create(
              project_id: project.id, source_term: source_term, source_language: source_language,
              target_term: target_term, target_locale_id: target_locale_id
            )
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
               when 'json' then JSON.parse(raw, symbolize_names: true)
               when 'csv' then CSV.parse(raw, headers: true, header_converters: :symbol).map(&:to_h)
               end
        Success(rows)
      rescue StandardError => e
        Failure([:validation, "Could not parse file: #{e.message}"])
      end
    end
  end
end
