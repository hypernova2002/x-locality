# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Models::User do
  describe '#password= / #authenticate' do
    it 'authenticates with the correct password' do
      user = create(:user, password: 'correct-horse-battery-staple')

      expect(user.authenticate('correct-horse-battery-staple')).to eq(user)
    end

    it 'rejects the wrong password' do
      user = create(:user, password: 'correct-horse-battery-staple')

      expect(user.authenticate('wrong-password')).to be(false)
    end

    it 'never stores the plaintext password' do
      user = create(:user, password: 'correct-horse-battery-staple')

      expect(user.password_digest).not_to eq('correct-horse-battery-staple')
    end
  end

  describe 'public_id' do
    it 'is generated on create with the user prefix' do
      user = create(:user)

      expect(user.public_id).to match(/\Auser_[A-Za-z0-9]{12}\z/)
    end
  end

  describe 'associations' do
    it 'belongs to an account' do
      account = create(:account)
      user = create(:user, account: account)

      expect(user.account.id).to eq(account.id)
    end
  end
end
