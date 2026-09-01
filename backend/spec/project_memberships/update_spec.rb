# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::ProjectMemberships::Update do
  describe "#call" do
    it "updates the role" do
      membership = create(:project_membership, role: "member")

      result = described_class.new.call(membership: membership, role: "admin")

      expect(result.value!.role).to eq("admin")
      expect(membership.reload.role).to eq("admin")
    end

    it "fails with :validation for an invalid role" do
      membership = create(:project_membership, role: "member")

      result = described_class.new.call(membership: membership, role: "owner")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
      expect(membership.reload.role).to eq("member")
    end
  end
end
