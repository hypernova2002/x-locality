# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Accounts::Delete do
  describe "#call" do
    it "destroys the account, cascading its users and projects" do
      account = create(:account)
      owner = create(:user, account: account, role: "owner")
      project = create(:project, account: account)

      described_class.new.call(account: account)

      expect(Backend::Models::Account[account.id]).to be_nil
      expect(Backend::Models::User[owner.id]).to be_nil
      expect(Backend::Models::Project[project.id]).to be_nil
    end
  end
end
