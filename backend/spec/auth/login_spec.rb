# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Auth::Login do
  describe '#call' do
    it 'succeeds with the correct email and password' do
      user = create(:user, email: 'dan@acme.test', password: 'supersecret123')

      result = described_class.new.call(email: 'dan@acme.test', password: 'supersecret123')

      expect(result).to be_success
      expect(result.value!.id).to eq(user.id)
    end

    it 'fails with :unauthorized for the wrong password' do
      create(:user, email: 'dan@acme.test', password: 'supersecret123')

      result = described_class.new.call(email: 'dan@acme.test', password: 'wrong')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:unauthorized)
    end

    it 'fails with :unauthorized for an unknown email' do
      result = described_class.new.call(email: 'nobody@acme.test', password: 'whatever')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:unauthorized)
    end
  end
end
