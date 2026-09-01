# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Users::Delete do
  describe "#call" do
    it "destroys a non-owner user" do
      user = create(:user, role: "member")

      result = described_class.new.call(user: user)

      expect(result).to be_success
      expect(Backend::Models::User[user.id]).to be_nil
    end

    it "fails with :validation when the user is the account owner" do
      user = create(:user, role: "owner")

      result = described_class.new.call(user: user)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
      expect(Backend::Models::User[user.id]).not_to be_nil
    end

    it "removes the user's project memberships via cascade, without deleting their translation version history" do
      account = create(:account)
      member = create(:user, account: account, role: "member")
      project = create(:project, account: account)
      create(:project_membership, project: project, user: member, role: "member")
      locale = create(:locale, project: project)
      translation = create(:translation, project: project, locale: locale)
      translation.record_version!(previous_value: nil, new_value: "hi", changed_by_type: "user", changed_by_user: member)

      described_class.new.call(user: member)

      expect(Backend::Models::ProjectMembership.where(user_id: member.id).count).to eq(0)
      version = translation.versions_dataset.first
      expect(version).not_to be_nil
      expect(version.changed_by_user_id).to be_nil
    end
  end
end
