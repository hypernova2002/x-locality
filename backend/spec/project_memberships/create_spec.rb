# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::ProjectMemberships::Create do
  describe '#call' do
    it 'adds an existing account user to the project with the given role' do
      account = create(:account)
      project = create(:project, account: account)
      member = create(:user, account: account, role: 'member')

      result = described_class.new.call(project: project, email: member.email, role: 'admin')

      membership = result.value!
      expect(membership.user_id).to eq(member.id)
      expect(membership.role).to eq('admin')
    end

    it 'fails with :validation for an invalid role' do
      account = create(:account)
      project = create(:project, account: account)
      member = create(:user, account: account, role: 'member')

      result = described_class.new.call(project: project, email: member.email, role: 'owner')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "fails with :not_found when no user with that email exists in the project's account" do
      project = create(:project)

      result = described_class.new.call(project: project, email: 'nobody@example.com', role: 'member')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it 'fails with :not_found when the email belongs to a user in a different account' do
      project = create(:project)
      other = create(:user)

      result = described_class.new.call(project: project, email: other.email, role: 'member')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it 'fails with :conflict when the user is the account owner' do
      account = create(:account)
      project = create(:project, account: account)
      owner = create(:user, account: account, role: 'owner')

      result = described_class.new.call(project: project, email: owner.email, role: 'member')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end

    it 'fails with :conflict when already a member of this project' do
      account = create(:account)
      project = create(:project, account: account)
      member = create(:user, account: account, role: 'member')
      create(:project_membership, project: project, user: member, role: 'member')

      result = described_class.new.call(project: project, email: member.email, role: 'admin')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end
  end
end
