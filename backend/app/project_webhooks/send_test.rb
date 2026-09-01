# frozen_string_literal: true

module Backend
  module ProjectWebhooks
    # Delivers synchronously (not queued) so the UI gets an immediate
    # success/failure result - reuses DeliverWebhookJob's own signing/
    # logging logic directly rather than duplicating it, since a Sidekiq
    # job is just a plain object that can be invoked outside the queue.
    class SendTest < Backend::Operation
      def call(project_webhook:)
        step deliver(project_webhook)
      end

      private

      def deliver(project_webhook)
        Backend::ProjectWebhooks::Jobs::DeliverWebhookJob.new.perform(
          project_webhook.id, "test", { "message" => "This is a test webhook delivery from x-locality." }
        )
        Success(true)
      rescue StandardError => e
        Failure([:validation, "Test delivery failed: #{e.message}"])
      end
    end
  end
end
