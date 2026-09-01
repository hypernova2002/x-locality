# frozen_string_literal: true

module Backend
  module Accounts
    # Deletes the account outright - cascades every project, user, and all
    # their data via DB foreign keys. Only the owner can call this
    # (enforced by the action), and there's no undo.
    class Delete < Backend::Operation
      def call(account:)
        account.destroy
        account
      end
    end
  end
end
