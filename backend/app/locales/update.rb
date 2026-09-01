# frozen_string_literal: true

module Backend
  module Locales
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent.
      def call(locale:, updates:)
        step check_not_system(locale)

        locale.update(updates.slice(:style_tone_text, :general_description, :target_language))
        locale
      end

      private

      def check_not_system(locale)
        return Failure([:forbidden, "System locales are read-only"]) if locale.system

        Success(true)
      end
    end
  end
end
