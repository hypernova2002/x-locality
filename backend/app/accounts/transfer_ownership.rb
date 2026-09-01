# frozen_string_literal: true

module Backend
  module Accounts
    class TransferOwnership < Backend::Operation
      def call(current_owner:, new_owner_email:)
        new_owner = step find_new_owner(current_owner, new_owner_email)

        Backend::Models::User.db.transaction do
          current_owner.update(role: 'member')
          new_owner.update(role: 'owner')
        end

        new_owner
      end

      private

      def find_new_owner(current_owner, new_owner_email)
        new_owner = Backend::Models::User.first(email: new_owner_email, account_id: current_owner.account_id)
        return Failure([:not_found, 'No user with this email in your account']) unless new_owner

        return Failure([:validation, "You're already the owner"]) if new_owner.id == current_owner.id

        Success(new_owner)
      end
    end
  end
end
