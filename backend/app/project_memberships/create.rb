# frozen_string_literal: true

module Backend
  module ProjectMemberships
    # Adds an EXISTING account user directly to a project - for an email
    # that doesn't have an account user yet, use Invites::Create instead.
    class Create < Backend::Operation
      ROLES = %w[admin member].freeze

      def call(project:, email:, role:)
        step check_role(role)

        user = step find_user(project, email)
        step check_not_already_member(project, user)

        Backend::Models::ProjectMembership.create(project_id: project.id, user_id: user.id, role: role)
      end

      private

      def check_role(role)
        return Failure([:validation, "role must be one of: #{ROLES.join(', ')}"]) unless ROLES.include?(role)

        Success(true)
      end

      def find_user(project, email)
        user = Backend::Models::User.first(email: email, account_id: project.account_id)
        return Failure([:not_found, 'No user with this email in your account - invite them instead']) unless user

        Success(user)
      end

      def check_not_already_member(project, user)
        if user.owner?
          return Failure([:conflict, 'This user is the account owner and already has access to every project'])
        end

        if project.project_memberships_dataset.first(user_id: user.id)
          return Failure([:conflict, 'This user is already a member of this project'])
        end

        Success(true)
      end
    end
  end
end
