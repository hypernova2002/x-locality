# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmConfig
              class Update < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  optional(:active_llm_provider_config_id).maybe(:string)
                  optional(:monthly_cost_limit_usd).maybe(:decimal, gteq?: 0)
                  optional(:monthly_token_limit).maybe(:integer, gteq?: 0)
                  optional(:alert_email).maybe(:string)
                  optional(:alert_threshold_percent).maybe(:integer, gteq?: 1, lteq?: 100)
                  optional(:langfuse_enabled).maybe(:bool)
                  optional(:langfuse_public_key).maybe(:string)
                  optional(:langfuse_secret_key).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  updates = request.params.to_h.slice(
                    :active_llm_provider_config_id, :monthly_cost_limit_usd, :monthly_token_limit,
                    :alert_email, :alert_threshold_percent,
                    :langfuse_enabled, :langfuse_public_key, :langfuse_secret_key
                  )
                  result = Backend::LlmConfigs::Update.new.call(project: project(request), updates: updates)

                  case result
                  in Success(config)
                    response.format = :json
                    response.body = Backend::Serializers::LlmConfigSerializer.new(config).serialize
                  in Failure[code, detail]
                    render_failure(response, code, detail)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
