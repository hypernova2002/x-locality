# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Models::APIKey do
  describe '.generate' do
    it 'returns a record whose plaintext key is decryptable via #key' do
      project = create(:project)

      api_key = described_class.generate(project: project, name: 'CI key')

      expect(api_key.key).to start_with(described_class::PREFIX)
    end

    it 'persists only a digest, never the plaintext, in key_digest' do
      project = create(:project)

      api_key = described_class.generate(project: project, name: 'CI key')

      expect(api_key.key_digest).not_to eq(api_key.key)
      expect(api_key.key_digest).to eq(described_class.digest(api_key.key))
    end
  end

  describe '.authenticate' do
    it 'finds the matching, non-revoked key' do
      project = create(:project)
      api_key = described_class.generate(project: project, name: 'CI key')

      # Compare by id, not full object equality - a fresh DB read has
      # microsecond-precision timestamps vs. the in-memory nanosecond ones.
      expect(described_class.authenticate(api_key.key).id).to eq(api_key.id)
    end

    it 'returns nil for a revoked key' do
      project = create(:project)
      api_key = described_class.generate(project: project, name: 'CI key')
      api_key.update(revoked_at: Time.now)

      expect(described_class.authenticate(api_key.key)).to be_nil
    end

    it 'returns nil for an unknown key' do
      expect(described_class.authenticate('xloc_does_not_exist')).to be_nil
    end

    it 'returns nil for blank input' do
      expect(described_class.authenticate('')).to be_nil
      expect(described_class.authenticate(nil)).to be_nil
    end
  end

  describe '#revoked?' do
    it 'is false when revoked_at is unset' do
      expect(create(:api_key).revoked?).to be(false)
    end

    it 'is true once revoked_at is set' do
      api_key = create(:api_key)
      api_key.update(revoked_at: Time.now)

      expect(api_key.revoked?).to be(true)
    end
  end
end
