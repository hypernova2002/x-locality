# frozen_string_literal: true

module Backend
  module ProjectWebhooks
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent.
      def call(project_webhook:, updates:)
        step check_valid_event_types(updates[:event_types]) if updates.key?(:event_types)

        project_webhook.update(updates.slice(:url, :event_types, :enabled))
        project_webhook
      end

      private

      def check_valid_event_types(event_types)
        unknown = event_types - Backend::Models::ProjectWebhook::EVENT_TYPES
        return Failure([:validation, "Unknown event type(s): #{unknown.join(', ')}"]) unless unknown.empty?

        return Failure([:validation, 'At least one event type is required']) if event_types.empty?

        Success(true)
      end
    end
  end
end
