# frozen_string_literal: true

module Backend
  module Users
    # Removes a user from the account entirely (not just from one project) -
    # cascades their project_memberships, and set_nulls their attribution on
    # api_keys/translation_versions rather than deleting that history.
    class Delete < Backend::Operation
      def call(user:)
        step check_not_owner(user)

        user.destroy
        user
      end

      private

      def check_not_owner(user)
        return Failure([:validation, "The account owner can't be deleted - transfer ownership first"]) if user.owner?

        Success(true)
      end
    end
  end
end
