# frozen_string_literal: true

require 'spec_helper'
require 'zlib'
require 'stringio'
require 'csv'
require 'json'

RSpec.describe Backend::GlossaryTerms::Export do
  def gunzip(bytes)
    Zlib::GzipReader.new(StringIO.new(bytes)).read
  end

  describe '#call' do
    it 'exports one gzip-compressed CSV row per glossary term' do
      project = create(:project, slug: 'acme')
      locale_fr = create(:locale, project: project, key: 'fr')
      create(:glossary_term, project: project, source_term: 'workspace', source_language: 'en',
                             target_term: 'espace de travail', target_locale_id: locale_fr.id)

      result = described_class.new.call(project: project, format: 'csv').value!

      expect(result[:filename]).to eq('glossary-acme.csv.gz')
      csv = CSV.parse(gunzip(result[:content]), headers: true)
      expect(csv.length).to eq(1)
      expect(csv.first['source_term']).to eq('workspace')
      expect(csv.first['source_language']).to eq('en')
      expect(csv.first['target_locale']).to eq('fr')
      expect(csv.first['target_term']).to eq('espace de travail')
    end

    it 'exports a blank target_locale for a wildcard (all-locales) term' do
      project = create(:project)
      create(:glossary_term, project: project, source_term: 'Acme Dashboard', target_locale_id: nil)

      result = described_class.new.call(project: project, format: 'csv').value!

      csv = CSV.parse(gunzip(result[:content]), headers: true)
      expect(csv.first['target_locale']).to be_nil
    end

    it 'exports gzip-compressed JSON' do
      project = create(:project)
      create(:glossary_term, project: project, source_term: 'workspace', source_language: 'en')

      result = described_class.new.call(project: project, format: 'json').value!

      rows = JSON.parse(gunzip(result[:content]))
      expect(rows.length).to eq(1)
      expect(rows.first['source_term']).to eq('workspace')
    end
  end
end
