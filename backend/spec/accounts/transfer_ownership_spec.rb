# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Accounts::TransferOwnership do
  describe '#call' do
    it 'makes the target user the owner and demotes the current owner to member' do
      account = create(:account)
      owner = create(:user, account: account, role: 'owner')
      member = create(:user, account: account, role: 'member')

      result = described_class.new.call(current_owner: owner, new_owner_email: member.email)

      new_owner = result.value!
      expect(new_owner.id).to eq(member.id)
      expect(new_owner.reload.role).to eq('owner')
      expect(owner.reload.role).to eq('member')
    end

    it 'fails with :not_found when no user with that email exists in the account' do
      owner = create(:user, role: 'owner')

      result = described_class.new.call(current_owner: owner, new_owner_email: 'nobody@example.com')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it 'fails with :not_found when the email belongs to a user in a different account' do
      owner = create(:user, role: 'owner')
      other = create(:user)

      result = described_class.new.call(current_owner: owner, new_owner_email: other.email)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it 'fails with :validation when transferring to yourself' do
      owner = create(:user, role: 'owner')

      result = described_class.new.call(current_owner: owner, new_owner_email: owner.email)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end
  end
end
