# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmProviderConfigs
              class Models < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:provider).filled(:string)
                  required(:api_key).filled(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::LlmProviderConfigs::ListModels.new.call(
                    provider: request.params[:provider], api_key: request.params[:api_key]
                  )

                  case result
                  in Success(*models)
                    response.format = :json
                    response.body = models.to_json
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
