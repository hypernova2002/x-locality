# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Projects::Create do
  describe "#call" do
    it "creates a project belonging to the given account" do
      account = create(:account)
      owner = create(:user, account: account, role: "owner")

      result = described_class.new.call(account: account, name: "Marketing Site", created_by_user: owner)

      expect(result).to be_success
      project = result.value!
      expect(project.account_id).to eq(account.id)
      expect(project.slug).to eq("marketing-site")
    end

    it "creates an llm_config with no active provider config yet" do
      account = create(:account)
      owner = create(:user, account: account, role: "owner")

      project = described_class.new.call(account: account, name: "Site", created_by_user: owner).value!

      expect(project.llm_config).to be_a(Backend::Models::LlmConfig)
      expect(project.llm_config.active_llm_provider_config).to be_nil
    end

    it "seeds the system locales" do
      account = create(:account)
      owner = create(:user, account: account, role: "owner")

      project = described_class.new.call(account: account, name: "Site", created_by_user: owner).value!

      expect(project.locales_dataset.where(system: true).count).to eq(Backend::SystemLocales.size)
    end

    it "does not create a membership row for the owner - they have implicit access" do
      account = create(:account)
      owner = create(:user, account: account, role: "owner")

      project = described_class.new.call(account: account, name: "Site", created_by_user: owner).value!

      expect(project.project_memberships_dataset.count).to eq(0)
    end

    it "grants the creator an admin membership when they aren't the owner" do
      account = create(:account)
      member = create(:user, account: account, role: "member")

      project = described_class.new.call(account: account, name: "Site", created_by_user: member).value!

      membership = project.project_memberships_dataset.first(user_id: member.id)
      expect(membership.role).to eq("admin")
    end

    it "fails with :conflict when the account already has a project with that slug" do
      account = create(:account)
      owner = create(:user, account: account, role: "owner")
      create(:project, account: account, slug: "marketing-site")

      result = described_class.new.call(account: account, name: "Marketing Site", created_by_user: owner)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end

    it "allows the same project name across different accounts" do
      create(:project, account: create(:account), slug: "marketing-site")
      account = create(:account)
      owner = create(:user, account: account, role: "owner")

      result = described_class.new.call(account: account, name: "Marketing Site", created_by_user: owner)

      expect(result).to be_success
    end
  end
end
