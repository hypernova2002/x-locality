# frozen_string_literal: true

require 'csv'
require 'json'
require 'zlib'
require 'stringio'

module Backend
  module ContextTags
    class Export < Backend::Operation
      COLUMNS = %i[key description].freeze

      def call(project:, format:)
        rows = project.context_tags_dataset.order(:key).all.map { |t| row_for(t) }
        content = format == 'json' ? JSON.generate(rows) : to_csv(rows)

        { content: gzip(content), filename: "context-tags-#{project.slug}.#{format}.gz" }
      end

      private

      def row_for(tag)
        { key: tag.key, description: tag.description }
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
