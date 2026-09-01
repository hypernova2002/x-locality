# frozen_string_literal: true

module Backend
  module Locales
    class Delete < Backend::Operation
      def call(locale:)
        step check_not_system(locale)

        locale.destroy
        locale
      end

      private

      def check_not_system(locale)
        return Failure([:forbidden, "System locales cannot be deleted"]) if locale.system

        Success(true)
      end
    end
  end
end
