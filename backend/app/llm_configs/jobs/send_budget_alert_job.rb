# frozen_string_literal: true

require 'sidekiq'

module Backend
  module LlmConfigs
    module Jobs
      class SendBudgetAlertJob
        include Sidekiq::Job

        def perform(project_id, tokens_used, cost_used)
          project = Backend::Models::Project[project_id]
          return unless project

          config = project.llm_config
          return unless config&.alert_email

          Backend::LlmConfigs::BudgetAlertMailer.deliver(
            project: project, config: config, tokens_used: tokens_used, cost_used: cost_used
          )
        end
      end
    end
  end
end
