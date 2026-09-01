# frozen_string_literal: true

module Backend
  module ProjectWebhooks
    # Enqueues one delivery job per enabled webhook subscribed to
    # event_type - a no-op (single indexed query) for the common case of a
    # project with no webhooks configured.
    class Notify < Backend::Operation
      def call(project:, event_type:, payload:)
        project.project_webhooks_dataset.where(enabled: true).all.each do |webhook|
          next unless webhook.subscribed_to?(event_type)

          Backend::ProjectWebhooks::Jobs::DeliverWebhookJob.perform_async(webhook.id, event_type, payload)
        end

        true
      end
    end
  end
end
