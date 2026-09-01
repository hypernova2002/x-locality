# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Translations::ListGrouped do
  let(:project) { create(:project) }
  let(:locale_fr) { create(:locale, project: project, key: 'fr') }
  let(:locale_de) { create(:locale, project: project, key: 'de') }

  describe '#call' do
    it 'groups multiple locale rows for the same key into one entry' do
      create(:translation, project: project, locale: locale_fr, key: 'cta', source_text: 'Buy now',
                           translated_text: 'Achetez', status: 'completed')
      create(:translation, project: project, locale: locale_de, key: 'cta', source_text: 'Buy now',
                           translated_text: 'Kaufen', status: 'completed')

      data = described_class.new.call(project: project).value!

      expect(data[:groups].size).to eq(1)
      group = data[:groups].first
      expect(group[:key]).to eq('cta')
      expect(group[:source_text]).to eq('Buy now')
      expect(group[:translations].map { |t| t[:locale] }).to contain_exactly('fr', 'de')
    end

    it "exposes the group's source language, preferring the explicit one over the detected one" do
      create(:translation, project: project, locale: locale_fr, key: 'explicit', source_language: 'en',
                           detected_language: 'de')
      create(:translation, project: project, locale: locale_fr, key: 'detected', source_language: nil,
                           detected_language: 'ja')

      data = described_class.new.call(project: project).value!
      by_key = data[:groups].to_h { |g| [g[:key], g[:source_language]] }

      expect(by_key['explicit']).to eq('en')
      expect(by_key['detected']).to eq('ja')
    end

    it 'keeps different keys as separate groups' do
      create(:translation, project: project, locale: locale_fr, key: 'a')
      create(:translation, project: project, locale: locale_fr, key: 'b')

      data = described_class.new.call(project: project).value!

      expect(data[:groups].map { |g| g[:key] }).to contain_exactly('a', 'b')
    end

    it "does not include another project's translations" do
      create(:translation, project: project, locale: locale_fr, key: 'mine')
      other_project = create(:project)
      other_locale = create(:locale, project: other_project)
      create(:translation, project: other_project, locale: other_locale, key: 'theirs')

      data = described_class.new.call(project: project).value!

      expect(data[:groups].map { |g| g[:key] }).to eq(['mine'])
    end

    it 'filters by a key substring' do
      create(:translation, project: project, locale: locale_fr, key: 'homepage-title')
      create(:translation, project: project, locale: locale_fr, key: 'button-post')

      data = described_class.new.call(project: project, key: 'home').value!

      expect(data[:groups].map { |g| g[:key] }).to eq(['homepage-title'])
    end

    it 'searches by a source text substring, not the key' do
      create(:translation, project: project, locale: locale_fr, key: 'a', source_text: 'Welcome home')
      create(:translation, project: project, locale: locale_fr, key: 'b', source_text: 'Buy now')

      data = described_class.new.call(project: project, search: 'welcome').value!

      expect(data[:groups].map { |g| g[:key] }).to eq(['a'])
    end

    it 'filters by source language, matching either the explicit or detected language' do
      create(:translation, project: project, locale: locale_fr, key: 'explicit', source_language: 'en')
      create(:translation, project: project, locale: locale_fr, key: 'detected', source_language: nil,
                           detected_language: 'en')
      create(:translation, project: project, locale: locale_fr, key: 'other', source_language: 'ja')

      data = described_class.new.call(project: project, source_language: 'en').value!

      expect(data[:groups].map { |g| g[:key] }).to contain_exactly('explicit', 'detected')
    end

    it 'filters by target language, to only the groups that have a translation in that locale' do
      create(:translation, project: project, locale: locale_fr, key: 'fr-only')
      create(:translation, project: project, locale: locale_de, key: 'de-only')

      data = described_class.new.call(project: project, target_language: 'de').value!

      expect(data[:groups].map { |g| g[:key] }).to eq(['de-only'])
    end

    it 'filters by llm provider' do
      create(:translation, project: project, locale: locale_fr, key: 'anthropic-one', llm_provider: 'anthropic')
      create(:translation, project: project, locale: locale_fr, key: 'gemini-one', llm_provider: 'gemini')

      data = described_class.new.call(project: project, llm_provider: 'gemini').value!

      expect(data[:groups].map { |g| g[:key] }).to eq(['gemini-one'])
    end

    it 'filters by locked status' do
      create(:translation, project: project, locale: locale_fr, key: 'locked-one', locked: true)
      create(:translation, project: project, locale: locale_fr, key: 'unlocked-one', locked: false)

      locked = described_class.new.call(project: project, locked: true).value!
      unlocked = described_class.new.call(project: project, locked: false).value!

      expect(locked[:groups].map { |g| g[:key] }).to eq(['locked-one'])
      expect(unlocked[:groups].map { |g| g[:key] }).to eq(['unlocked-one'])
    end

    it 'filters by an llm model substring' do
      create(:translation, project: project, locale: locale_fr, key: 'opus', model_used: 'claude-opus-5')
      create(:translation, project: project, locale: locale_fr, key: 'flash', model_used: 'gemini-3.5-flash')

      data = described_class.new.call(project: project, llm_model: 'opus').value!

      expect(data[:groups].map { |g| g[:key] }).to eq(['opus'])
    end

    it 'paginates by key (alphabetical, keyset via after)' do
      %w[a b c].each { |k| create(:translation, project: project, locale: locale_fr, key: k) }

      first_page = described_class.new.call(project: project, limit: 2).value!
      expect(first_page[:groups].map { |g| g[:key] }).to eq(%w[a b])
      expect(first_page[:has_more]).to be(true)
      expect(first_page[:next_cursor]).to eq('b')

      second_page = described_class.new.call(project: project, limit: 2, after: first_page[:next_cursor]).value!
      expect(second_page[:groups].map { |g| g[:key] }).to eq(['c'])
      expect(second_page[:has_more]).to be(false)
    end

    it 'returns an empty result for a project with no translations' do
      data = described_class.new.call(project: project).value!

      expect(data[:groups]).to eq([])
      expect(data[:has_more]).to be(false)
    end
  end
end
