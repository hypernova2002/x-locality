# frozen_string_literal: true

module Backend
  module Serializers
    # Never includes the token - only its existence and metadata.
    class InviteSerializer
      include Alba::Resource

      attributes :email, :role, :expires_at, :created_at

      attribute :id, &:public_id

      attribute :invited_by_email do |invite|
        invite.invited_by_user&.email
      end
    end
  end
end
