# frozen_string_literal: true

require "securerandom"

module Backend
  module ProjectWebhooks
    class Create < Backend::Operation
      def call(project:, url:, event_types:)
        step check_valid_event_types(event_types)

        Backend::Models::ProjectWebhook.create(
          project_id: project.id, url: url, event_types: event_types, secret: SecureRandom.hex(32)
        )
      end

      private

      def check_valid_event_types(event_types)
        unknown = event_types - Backend::Models::ProjectWebhook::EVENT_TYPES
        return Failure([:validation, "Unknown event type(s): #{unknown.join(', ')}"]) unless unknown.empty?

        return Failure([:validation, "At least one event type is required"]) if event_types.empty?

        Success(true)
      end
    end
  end
end
