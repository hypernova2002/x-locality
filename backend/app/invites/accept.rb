# frozen_string_literal: true

module Backend
  module Invites
    class Accept < Backend::Operation
      def call(token:, password:)
        invite = step find_invite(token)
        step check_available(invite)

        user = nil
        Backend::Models::User.db.transaction do
          user = Backend::Models::User.create(
            account_id: invite.account_id, email: invite.email, password: password, role: 'member'
          )
          Backend::Models::ProjectMembership.create(project_id: invite.project_id, user_id: user.id, role: invite.role)
          invite.update(accepted_at: Time.now)
        end

        user
      end

      private

      def find_invite(token)
        invite = Backend::Models::Invite.find_by_token(token)
        return Failure([:not_found, 'Invite not found']) unless invite

        Success(invite)
      end

      def check_available(invite)
        return Failure([:validation, 'This invite has already been accepted']) if invite.accepted?
        return Failure([:validation, 'This invite has expired']) if invite.expired?

        if Backend::Models::User.first(email: invite.email)
          return Failure([:conflict, 'An account already exists for this email'])
        end

        Success(true)
      end
    end
  end
end
