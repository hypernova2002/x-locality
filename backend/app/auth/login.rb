# frozen_string_literal: true

module Backend
  module Auth
    class Login < Backend::Operation
      def call(email:, password:)
        step authenticate(email, password)
      end

      private

      def authenticate(email, password)
        user = Backend::Models::User.first(email: email)
        return Failure([:unauthorized, "Invalid email or password"]) unless user && user.authenticate(password)

        Success(user)
      end
    end
  end
end
