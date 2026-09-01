# frozen_string_literal: true

require "csv"
require "json"
require "zlib"
require "stringio"
require "base64"

module Backend
  module ContextTags
    # Upserts context tags from a long-format CSV/JSON export (see Export).
    class Import < Backend::Operation
      def call(project:, format:, content_base64:, compressed:)
        raw = step decode(content_base64, compressed)
        rows = step parse(raw, format)

        created = 0
        updated = 0
        skipped = []

        rows.each do |row|
          key = row[:key].to_s.strip

          if key.empty?
            skipped << { key: key, reason: "missing_key" }
            next
          end

          description = row[:description].to_s.empty? ? nil : row[:description].to_s
          existing = project.context_tags_dataset.first(key: key)

          if existing
            existing.update(description: description)
            updated += 1
          else
            Backend::Models::ContextTag.create(project_id: project.id, key: key, description: description)
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
