# frozen_string_literal: true

module Backend
  module Locales
    class Create < Backend::Operation
      def call(project:, key:, target_language:, style_tone_text: nil, general_description: nil)
        step check_key_available(project, key)

        Backend::Models::Locale.create(
          project_id: project.id,
          key: key,
          target_language: target_language,
          style_tone_text: style_tone_text,
          general_description: general_description,
          system: false
        )
      end

      private

      def check_key_available(project, key)
        if project.locales_dataset.first(key: key)
          return Failure([:conflict, 'A locale with this key already exists on this project'])
        end

        Success(true)
      end
    end
  end
end
