# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::ProjectMemberships::Delete do
  describe '#call' do
    it 'destroys the membership' do
      membership = create(:project_membership)

      described_class.new.call(membership: membership)

      expect(Backend::Models::ProjectMembership[membership.id]).to be_nil
    end
  end
end
