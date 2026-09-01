# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::PublicId do
  describe '.generate' do
    it 'prefixes the id' do
      expect(described_class.generate('proj')).to start_with('proj_')
    end

    it 'produces ids of the expected length' do
      id = described_class.generate('proj', length: 12)

      expect(id.delete_prefix('proj_').length).to eq(12)
    end

    it 'produces unique ids across calls' do
      ids = Array.new(1000) { described_class.generate('proj') }

      expect(ids.uniq.size).to eq(1000)
    end
  end
end
