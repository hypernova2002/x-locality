# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Invites::Create do
  describe "#call" do
    it "creates a pending invite and delivers it by email" do
      project = create(:project)
      inviter = create(:user, account: project.account, role: "owner")

      expect(Backend::Invites::InviteMailer).to receive(:deliver).with(
        invite: an_instance_of(Backend::Models::Invite), plaintext_token: an_instance_of(String),
        project: project, invited_by_user: inviter
      )

      result = described_class.new.call(project: project, email: "new@example.com", role: "member", invited_by_user: inviter)

      invite = result.value!
      expect(invite.email).to eq("new@example.com")
      expect(invite.role).to eq("member")
      expect(invite.project_id).to eq(project.id)
      expect(invite.pending?).to be(true)
    end

    it "fails with :validation for an invalid role" do
      project = create(:project)

      result = described_class.new.call(project: project, email: "new@example.com", role: "owner", invited_by_user: nil)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "fails with :conflict when the email already belongs to a user in this account" do
      account = create(:account)
      project = create(:project, account: account)
      existing = create(:user, account: account)

      result = described_class.new.call(project: project, email: existing.email, role: "member", invited_by_user: nil)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end

    it "fails with :conflict when the email belongs to a user in a different account" do
      project = create(:project)
      other = create(:user)

      result = described_class.new.call(project: project, email: other.email, role: "member", invited_by_user: nil)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end

    it "supersedes an earlier pending invite for the same project/email" do
      project = create(:project)
      allow(Backend::Invites::InviteMailer).to receive(:deliver)

      first_result = described_class.new.call(project: project, email: "new@example.com", role: "member", invited_by_user: nil)
      first_invite_id = first_result.value!.id

      described_class.new.call(project: project, email: "new@example.com", role: "admin", invited_by_user: nil)

      expect(Backend::Models::Invite[first_invite_id]).to be_nil
      expect(project.invites_dataset.where(email: "new@example.com", accepted_at: nil).count).to eq(1)
    end
  end
end
