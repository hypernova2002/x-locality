# frozen_string_literal: true

module Backend
  module Auth
    class Signup < Backend::Operation
      def call(account_name:, email:, password:)
        step check_email_available(email)

        user = nil
        Backend::Models::User.db.transaction do
          account = Backend::Models::Account.create(name: account_name)
          user = Backend::Models::User.create(
            account: account, email: email, password: password, role: 'owner'
          )
        end

        user
      end

      private

      def check_email_available(email)
        return Failure([:conflict, 'Email is already in use']) if Backend::Models::User.first(email: email)

        Success(true)
      end
    end
  end
end
