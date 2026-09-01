# frozen_string_literal: true

module Backend
  module ProjectWebhooks
    class Delete < Backend::Operation
      def call(project_webhook:)
        project_webhook.destroy
        project_webhook
      end
    end
  end
end
