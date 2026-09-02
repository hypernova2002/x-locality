# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmProviderConfigs
              class Update < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:id).filled(:string)
                  optional(:name).filled(:string)
                  optional(:description).maybe(:string)
                  optional(:provider).filled(:string)
                  optional(:model).maybe(:string)
                  optional(:api_key).maybe(:string)
                  optional(:api_secret).maybe(:string)
                  optional(:region).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  config = project(request).llm_provider_configs_dataset.first(public_id: request.params[:id])
                  unless config
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'LLM provider config not found')
                  end

                  updates = request.params.to_h.slice(:name, :description, :provider, :model, :api_key, :api_secret,
                                                      :region)
                  result = Backend::LlmProviderConfigs::Update.new.call(config: config, updates: updates)

                  case result
                  in Success(updated)
                    response.format = :json
                    response.body = Backend::Serializers::LlmProviderConfigSerializer.new(updated).serialize
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
