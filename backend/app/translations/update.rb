# frozen_string_literal: true

module Backend
  module Translations
    class Update < Backend::Operation
      def call(translation:, translated_text:, changed_by_user:)
        previous_value = translation.translated_text

        translation.update(
          translated_text: translated_text,
          status: "completed",
          generated_by: "user"
        )

        translation.record_version!(
          previous_value: previous_value,
          new_value: translated_text,
          changed_by_type: "user",
          changed_by_user: changed_by_user
        )

        translation
      end
    end
  end
end
