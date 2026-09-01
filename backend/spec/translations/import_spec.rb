# frozen_string_literal: true

require "spec_helper"
require "zlib"
require "stringio"
require "base64"
require "csv"
require "json"

RSpec.describe Backend::Translations::Import do
  def gzip_b64(content)
    io = StringIO.new
    writer = Zlib::GzipWriter.new(io)
    writer.write(content)
    writer.close
    Base64.strict_encode64(io.string)
  end

  let(:project) { create(:project) }
  let!(:locale_fr) { create(:locale, project: project, key: "fr", target_language: "fr") }

  describe "#call" do
    it "creates new translations from CSV rows" do
      csv = CSV.generate do |c|
        c << %w[key locale source_text translated_text status]
        c << ["cta", "fr", "Buy", "Achetez", "completed"]
      end

      result = described_class.new.call(
        project: project, format: "csv", content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:created]).to eq(1)
      expect(result[:updated]).to eq(0)
      translation = project.translations_dataset.first(key: "cta", locale_id: locale_fr.id)
      expect(translation.translated_text).to eq("Achetez")
      expect(translation.status).to eq("completed")
      expect(translation.generated_by).to eq("user")
    end

    it "updates an existing translation" do
      create(:translation, project: project, locale: locale_fr, key: "cta", source_text: "Buy",
        translated_text: "old")
      csv = CSV.generate do |c|
        c << %w[key locale source_text translated_text status]
        c << ["cta", "fr", "Buy", "new", "completed"]
      end

      result = described_class.new.call(
        project: project, format: "csv", content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:updated]).to eq(1)
      expect(project.translations_dataset.first(key: "cta").translated_text).to eq("new")
    end

    it "skips a locked translation without overwriting it" do
      create(:translation, project: project, locale: locale_fr, key: "cta", source_text: "Buy",
        translated_text: "keep me", locked: true)
      csv = CSV.generate do |c|
        c << %w[key locale source_text translated_text]
        c << ["cta", "fr", "Buy", "overwritten?"]
      end

      result = described_class.new.call(
        project: project, format: "csv", content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:skipped]).to eq([{ key: "cta", locale: "fr", reason: "locked" }])
      expect(project.translations_dataset.first(key: "cta").translated_text).to eq("keep me")
    end

    it "skips rows with an unknown locale" do
      csv = CSV.generate do |c|
        c << %w[key locale source_text]
        c << ["cta", "de", "Buy"]
      end

      result = described_class.new.call(
        project: project, format: "csv", content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:skipped]).to eq([{ key: "cta", locale: "de", reason: "unknown_locale" }])
    end

    it "skips rows missing source_text" do
      csv = CSV.generate do |c|
        c << %w[key locale source_text]
        c << ["cta", "fr", ""]
      end

      result = described_class.new.call(
        project: project, format: "csv", content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:skipped]).to eq([{ key: "cta", locale: "fr", reason: "missing_source_text" }])
    end

    it "imports from uncompressed JSON" do
      json = JSON.generate([{ key: "cta", locale: "fr", source_text: "Buy", translated_text: "Achetez" }])

      result = described_class.new.call(
        project: project, format: "json", content_base64: Base64.strict_encode64(json), compressed: false
      ).value!

      expect(result[:created]).to eq(1)
    end

    it "fails with :validation when the content can't be decoded" do
      result = described_class.new.call(
        project: project, format: "csv", content_base64: Base64.strict_encode64("not gzip"), compressed: true
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "fails with :validation when the parsed content isn't valid for the format" do
      result = described_class.new.call(
        project: project, format: "json", content_base64: Base64.strict_encode64("not json"), compressed: false
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end
  end
end
