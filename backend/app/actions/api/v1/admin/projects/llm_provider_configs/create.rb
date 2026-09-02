# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmProviderConfigs
              class Create < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:name).filled(:string)
                  required(:provider).filled(:string)
                  optional(:description).maybe(:string)
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

                  result = Backend::LlmProviderConfigs::Create.new.call(
                    project: project(request),
                    name: request.params[:name],
                    provider: request.params[:provider],
                    description: request.params[:description],
                    model: request.params[:model],
                    api_key: request.params[:api_key],
                    api_secret: request.params[:api_secret],
                    region: request.params[:region]
                  )

                  case result
                  in Success(config)
                    response.status = 201
                    response.format = :json
                    response.body = Backend::Serializers::LlmProviderConfigSerializer.new(config).serialize
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
