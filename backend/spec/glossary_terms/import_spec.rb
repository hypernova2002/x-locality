# frozen_string_literal: true

require 'spec_helper'
require 'zlib'
require 'stringio'
require 'base64'
require 'csv'
require 'json'

RSpec.describe Backend::GlossaryTerms::Import do
  def gzip_b64(content)
    io = StringIO.new
    writer = Zlib::GzipWriter.new(io)
    writer.write(content)
    writer.close
    Base64.strict_encode64(io.string)
  end

  let(:project) { create(:project) }
  let!(:locale_fr) { create(:locale, project: project, key: 'fr') }

  describe '#call' do
    it 'creates a new glossary term from CSV rows' do
      csv = CSV.generate do |c|
        c << %w[source_term source_language target_locale target_term]
        c << ['workspace', 'en', 'fr', 'espace de travail']
      end

      result = described_class.new.call(
        project: project, format: 'csv', content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:created]).to eq(1)
      expect(result[:updated]).to eq(0)
      term = project.glossary_terms_dataset.first(source_term: 'workspace')
      expect(term.target_term).to eq('espace de travail')
      expect(term.target_locale_id).to eq(locale_fr.id)
    end

    it 'creates a wildcard (all-locales) term when target_locale is blank' do
      csv = CSV.generate do |c|
        c << %w[source_term source_language target_locale target_term]
        c << ['Acme Dashboard', 'en', '', 'Acme Dashboard']
      end

      result = described_class.new.call(
        project: project, format: 'csv', content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:created]).to eq(1)
      expect(project.glossary_terms_dataset.first(source_term: 'Acme Dashboard').target_locale_id).to be_nil
    end

    it 'updates an existing term matched on source_term/source_language/target_locale' do
      create(:glossary_term, project: project, source_term: 'workspace', source_language: 'en',
                             target_term: 'old', target_locale_id: locale_fr.id)
      csv = CSV.generate do |c|
        c << %w[source_term source_language target_locale target_term]
        c << %w[workspace en fr new]
      end

      result = described_class.new.call(
        project: project, format: 'csv', content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:updated]).to eq(1)
      expect(project.glossary_terms_dataset.first(source_term: 'workspace').target_term).to eq('new')
    end

    it 'skips rows with an unknown target_locale' do
      csv = CSV.generate do |c|
        c << %w[source_term source_language target_locale target_term]
        c << %w[workspace en de Arbeitsbereich]
      end

      result = described_class.new.call(
        project: project, format: 'csv', content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:skipped]).to eq([{ key: 'workspace', reason: 'unknown_target_locale' }])
    end

    it 'skips rows missing a required field' do
      csv = CSV.generate do |c|
        c << %w[source_term source_language target_locale target_term]
        c << ['workspace', 'en', '', '']
      end

      result = described_class.new.call(
        project: project, format: 'csv', content_base64: gzip_b64(csv), compressed: true
      ).value!

      expect(result[:skipped]).to eq([{ key: 'workspace', reason: 'missing_required_field' }])
    end

    it 'imports from uncompressed JSON' do
      json = JSON.generate([{ source_term: 'workspace', source_language: 'en', target_term: 'espace de travail' }])

      result = described_class.new.call(
        project: project, format: 'json', content_base64: Base64.strict_encode64(json), compressed: false
      ).value!

      expect(result[:created]).to eq(1)
    end

    it "fails with :validation when the content can't be decoded" do
      result = described_class.new.call(
        project: project, format: 'csv', content_base64: Base64.strict_encode64('not gzip'), compressed: true
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "fails with :validation when the parsed content isn't valid for the format" do
      result = described_class.new.call(
        project: project, format: 'json', content_base64: Base64.strict_encode64('not json'), compressed: false
      )

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end
  end
end
