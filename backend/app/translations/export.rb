# frozen_string_literal: true

require "csv"
require "json"
require "zlib"
require "stringio"

module Backend
  module Translations
    # Long format - one row per (key, locale) pair - so the column count
    # doesn't shift as locales are added/removed, and re-importing an
    # unmodified export is a no-op.
    class Export < Backend::Operation
      COLUMNS = %i[
        key locale source_text source_language translated_text status locked
        generated_by model_used llm_provider updated_at
      ].freeze

      def call(project:, format:)
        rows = project.translations_dataset.order(:key, :locale_id).eager(:locale).all.map { |t| row_for(t) }
        content = format == "json" ? JSON.generate(rows) : to_csv(rows)

        { content: gzip(content), filename: "translations-#{project.slug}.#{format}.gz" }
      end

      private

      def row_for(translation)
        {
          key: translation.key,
          locale: translation.locale.key,
          source_text: translation.source_text,
          source_language: translation.source_language,
          translated_text: translation.translated_text,
          status: translation.status,
          locked: translation.locked,
          generated_by: translation.generated_by,
          model_used: translation.model_used,
          llm_provider: translation.llm_provider,
          updated_at: translation.updated_at.iso8601
        }
      end

      def to_csv(rows)
        CSV.generate do |csv|
          csv << COLUMNS
          rows.each { |row| csv << COLUMNS.map { |col| row[col] } }
        end
      end

      def gzip(content)
        io = StringIO.new
        writer = Zlib::GzipWriter.new(io)
        writer.write(content)
        writer.close
        io.string
      end
    end
  end
end
