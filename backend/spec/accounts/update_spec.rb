# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Accounts::Update do
  describe '#call' do
    it 'updates the timezone' do
      account = create(:account)

      result = described_class.new.call(account: account, updates: { timezone: 'America/New_York' })

      expect(result.value!.timezone).to eq('America/New_York')
      expect(account.reload.timezone).to eq('America/New_York')
    end

    it 'defaults to UTC for a newly created account' do
      account = create(:account)

      expect(account.timezone).to eq('UTC')
    end

    it 'fails with :validation for a blank timezone' do
      account = create(:account)

      result = described_class.new.call(account: account, updates: { timezone: '' })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it 'updates the name' do
      account = create(:account, name: 'Old Name')

      result = described_class.new.call(account: account, updates: { name: 'New Name' })

      expect(result.value!.name).to eq('New Name')
    end

    it 'fails with :validation for a blank name' do
      account = create(:account, name: 'Original')

      result = described_class.new.call(account: account, updates: { name: '' })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
      expect(account.reload.name).to eq('Original')
    end

    it 'updates the logo_url and correspondence_name' do
      account = create(:account)

      result = described_class.new.call(
        account: account,
        updates: { logo_url: 'https://example.com/logo.png', correspondence_name: 'Acme Support' }
      )

      updated = result.value!
      expect(updated.logo_url).to eq('https://example.com/logo.png')
      expect(updated.correspondence_name).to eq('Acme Support')
    end

    it 'leaves fields untouched when absent from updates' do
      account = create(:account, name: 'Original')
      account.update(timezone: 'Asia/Tokyo')

      described_class.new.call(account: account, updates: {})

      expect(account.reload.name).to eq('Original')
      expect(account.reload.timezone).to eq('Asia/Tokyo')
    end
  end
end
