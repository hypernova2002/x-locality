# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Invites::Accept do
  describe '#call' do
    it "creates a member-role user and a project_membership with the invite's role" do
      project = create(:project)
      invite, token = Backend::Models::Invite.generate(
        account: project.account, project: project, email: 'new@example.com', role: 'admin'
      )

      result = described_class.new.call(token: token, password: 'supersecret123')

      user = result.value!
      expect(user.email).to eq('new@example.com')
      expect(user.role).to eq('member')
      expect(user.account_id).to eq(project.account_id)

      membership = project.project_memberships_dataset.first(user_id: user.id)
      expect(membership.role).to eq('admin')
      expect(invite.reload.accepted_at).not_to be_nil
    end

    it 'fails with :not_found for an unknown token' do
      result = described_class.new.call(token: 'bogus', password: 'supersecret123')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end

    it 'fails with :validation when already accepted' do
      project = create(:project)
      invite, token = Backend::Models::Invite.generate(
        account: project.account, project: project, email: 'new@example.com', role: 'member'
      )
      invite.update(accepted_at: Time.now)

      result = described_class.new.call(token: token, password: 'supersecret123')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it 'fails with :validation when expired' do
      project = create(:project)
      invite, token = Backend::Models::Invite.generate(
        account: project.account, project: project, email: 'new@example.com', role: 'member'
      )
      invite.update(expires_at: Time.now - 1)

      result = described_class.new.call(token: token, password: 'supersecret123')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it 'fails with :conflict when a user with that email now exists' do
      project = create(:project)
      _, token = Backend::Models::Invite.generate(
        account: project.account, project: project, email: 'new@example.com', role: 'member'
      )
      create(:user, email: 'new@example.com')

      result = described_class.new.call(token: token, password: 'supersecret123')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end
  end
end
