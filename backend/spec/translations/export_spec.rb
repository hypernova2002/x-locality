# frozen_string_literal: true

require 'spec_helper'
require 'zlib'
require 'stringio'
require 'csv'
require 'json'

RSpec.describe Backend::Translations::Export do
  def gunzip(bytes)
    Zlib::GzipReader.new(StringIO.new(bytes)).read
  end

  describe '#call' do
    it 'exports one gzip-compressed CSV row per key/locale pair' do
      project = create(:project, slug: 'acme')
      locale_fr = create(:locale, project: project, key: 'fr', target_language: 'fr')
      create(:translation, project: project, locale: locale_fr, key: 'cta', source_text: 'Buy',
                           translated_text: 'Achetez', status: 'completed')

      result = described_class.new.call(project: project, format: 'csv').value!

      expect(result[:filename]).to eq('translations-acme.csv.gz')
      csv = CSV.parse(gunzip(result[:content]), headers: true)
      expect(csv.length).to eq(1)
      expect(csv.first['key']).to eq('cta')
      expect(csv.first['locale']).to eq('fr')
      expect(csv.first['translated_text']).to eq('Achetez')
    end

    it 'exports gzip-compressed JSON' do
      project = create(:project)
      locale_fr = create(:locale, project: project, key: 'fr', target_language: 'fr')
      create(:translation, project: project, locale: locale_fr, key: 'cta', source_text: 'Buy')

      result = described_class.new.call(project: project, format: 'json').value!

      rows = JSON.parse(gunzip(result[:content]))
      expect(rows.length).to eq(1)
      expect(rows.first['key']).to eq('cta')
      expect(rows.first['locale']).to eq('fr')
    end
  end
end
