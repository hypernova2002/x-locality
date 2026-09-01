# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Locales::Update do
  describe '#call' do
    it 'updates style_tone_text and general_description on a custom locale' do
      locale = create(:locale, system: false, target_language: 'fr')

      result = described_class.new.call(
        locale: locale, updates: { style_tone_text: 'Warm', general_description: 'Landing pages' }
      )

      updated = result.value!
      expect(updated.style_tone_text).to eq('Warm')
      expect(updated.general_description).to eq('Landing pages')
    end

    it 'allows changing target_language on a custom locale' do
      locale = create(:locale, system: false, target_language: 'fr')

      updated = described_class.new.call(locale: locale, updates: { target_language: 'es' }).value!

      expect(updated.target_language).to eq('es')
    end

    it 'rejects target_language updates on a system locale' do
      locale = create(:locale, system: true, target_language: 'fr')

      result = described_class.new.call(locale: locale, updates: { target_language: 'es' })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
      expect(locale.reload.target_language).to eq('fr')
    end

    it 'rejects style_tone_text updates on a system locale' do
      locale = create(:locale, system: true, target_language: 'fr')

      result = described_class.new.call(locale: locale, updates: { style_tone_text: 'Formal' })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:forbidden)
      expect(locale.reload.style_tone_text).to be_nil
    end
  end
end
