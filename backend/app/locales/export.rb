# frozen_string_literal: true

require 'csv'
require 'json'
require 'zlib'
require 'stringio'

module Backend
  module Locales
    class Export < Backend::Operation
      COLUMNS = %i[key target_language style_tone_text general_description system].freeze

      def call(project:, format:)
        rows = project.locales_dataset.order(:key).all.map { |l| row_for(l) }
        content = format == 'json' ? JSON.generate(rows) : to_csv(rows)

        { content: gzip(content), filename: "locales-#{project.slug}.#{format}.gz" }
      end

      private

      def row_for(locale)
        {
          key: locale.key,
          target_language: locale.target_language,
          style_tone_text: locale.style_tone_text,
          general_description: locale.general_description,
          system: locale.system
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
