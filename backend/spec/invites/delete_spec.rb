# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Invites::Delete do
  describe "#call" do
    it "destroys the invite" do
      project = create(:project)
      invite, = Backend::Models::Invite.generate(
        account: project.account, project: project, email: "new@example.com", role: "member"
      )

      described_class.new.call(invite: invite)

      expect(Backend::Models::Invite[invite.id]).to be_nil
    end
  end
end
