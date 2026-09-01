# frozen_string_literal: true

require "csv"
require "json"
require "zlib"
require "stringio"

module Backend
  module GlossaryTerms
    class Export < Backend::Operation
      COLUMNS = %i[source_term source_language target_locale target_term].freeze

      def call(project:, format:)
        rows = project.glossary_terms_dataset.order(:source_term).eager(:target_locale).all.map { |t| row_for(t) }
        content = format == "json" ? JSON.generate(rows) : to_csv(rows)

        { content: gzip(content), filename: "glossary-#{project.slug}.#{format}.gz" }
      end

      private

      def row_for(term)
        {
          source_term: term.source_term,
          source_language: term.source_language,
          # blank means the mapping applies regardless of target locale.
          target_locale: term.target_locale&.key,
          target_term: term.target_term
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
