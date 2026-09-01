# frozen_string_literal: true

require 'csv'
require 'json'
require 'zlib'
require 'stringio'
require 'base64'

module Backend
  module Locales
    # Upserts locales from a long-format CSV/JSON export (see Export). A row
    # matching an existing system locale is skipped rather than overwritten -
    # system locales aren't user-editable anywhere else either. `system` in
    # an imported row is otherwise ignored - it's a system-controlled flag,
    # not user data, so a newly-created locale from import is never system.
    class Import < Backend::Operation
      def call(project:, format:, content_base64:, compressed:)
        raw = step decode(content_base64, compressed)
        rows = step parse(raw, format)

        created = 0
        updated = 0
        skipped = []

        rows.each do |row|
          key = row[:key].to_s.strip
          target_language = row[:target_language].to_s.strip

          if key.empty? || target_language.empty?
            skipped << { key: key, reason: 'missing_key_or_target_language' }
            next
          end

          existing = project.locales_dataset.first(key: key)
          if existing&.system
            skipped << { key: key, reason: 'system' }
            next
          end

          attrs = {
            target_language: target_language,
            style_tone_text: row[:style_tone_text].to_s.empty? ? nil : row[:style_tone_text].to_s,
            general_description: row[:general_description].to_s.empty? ? nil : row[:general_description].to_s
          }

          if existing
            existing.update(attrs)
            updated += 1
          else
            Backend::Models::Locale.create(attrs.merge(project_id: project.id, key: key, system: false))
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
