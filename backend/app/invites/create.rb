# frozen_string_literal: true

module Backend
  module Invites
    class Create < Backend::Operation
      ROLES = %w[admin member].freeze

      def call(project:, email:, role:, invited_by_user:)
        step check_role(role)
        step check_email_available(project, email)

        # A fresh invite supersedes any earlier pending one for the same
        # project/email rather than leaving multiple valid links around.
        project.invites_dataset.where(email: email).where(accepted_at: nil).destroy

        invite, plaintext_token = Backend::Models::Invite.generate(
          account: project.account, project: project, email: email, role: role, invited_by_user: invited_by_user
        )

        Backend::Invites::InviteMailer.deliver(
          invite: invite, plaintext_token: plaintext_token, project: project, invited_by_user: invited_by_user
        )

        invite
      end

      private

      def check_role(role)
        return Failure([:validation, "role must be one of: #{ROLES.join(", ")}"]) unless ROLES.include?(role)

        Success(true)
      end

      def check_email_available(project, email)
        existing = Backend::Models::User.first(email: email)
        return Success(true) unless existing

        if existing.account_id == project.account_id
          Failure([:conflict, "This user is already in your account - add them directly instead of inviting"])
        else
          Failure([:conflict, "This email is already registered to a different account"])
        end
      end
    end
  end
end
