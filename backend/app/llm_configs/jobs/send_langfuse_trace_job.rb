# frozen_string_literal: true

require "sidekiq"

module Backend
  module LlmConfigs
    module Jobs
      class SendLangfuseTraceJob
        include Sidekiq::Job

        def perform(project_id, trace)
          base_url = Hanami.app["settings"].langfuse_base_url
          return if base_url.to_s.empty?

          project = Backend::Models::Project[project_id]
          return unless project

          config = project.llm_config
          return unless config&.langfuse_configured?

          Backend::Langfuse::Client.new(
            base_url: base_url,
            public_key: config.langfuse_public_key,
            secret_key: config.langfuse_secret_key
          ).send_generation(trace)
        end
      end
    end
  end
end
