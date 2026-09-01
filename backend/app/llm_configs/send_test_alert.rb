# frozen_string_literal: true

module Backend
  module LlmConfigs
    class SendTestAlert < Backend::Operation
      def call(project:)
        config = project.llm_config
        step check_email(config)

        step send_test(project, config)
      end

      private

      def check_email(config)
        unless config&.alert_email
          return Failure([:validation, "Set an alert email before sending a test"])
        end

        Success(true)
      end

      def send_test(project, config)
        Backend::LlmConfigs::BudgetAlertMailer.deliver_test(project: project, config: config)
        Success(true)
      rescue StandardError => e
        Failure([:validation, "Could not send test email: #{e.message}"])
      end
    end
  end
end
