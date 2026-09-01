# frozen_string_literal: true

module Backend
  module Accounts
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent.
      def call(account:, updates:)
        step check_name(updates[:name]) if updates.key?(:name)
        step check_timezone(updates[:timezone]) if updates.key?(:timezone)

        account.update(updates.slice(:name, :timezone, :logo_url, :correspondence_name))
        account
      end

      private

      def check_name(name)
        return Failure([:validation, "name can't be blank"]) if name.nil? || name.strip.empty?

        Success(true)
      end

      def check_timezone(timezone)
        return Failure([:validation, "timezone can't be blank"]) if timezone.nil? || timezone.strip.empty?

        Success(true)
      end
    end
  end
end
