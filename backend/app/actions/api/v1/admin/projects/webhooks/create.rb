# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Webhooks
              class Create < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:url).filled(:string)
                  required(:event_types).array(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::ProjectWebhooks::Create.new.call(
                    project: project(request),
                    url: request.params[:url],
                    event_types: request.params[:event_types]
                  )

                  case result
                  in Success(webhook)
                    response.status = 201
                    response.format = :json
                    response.body = Backend::Serializers::ProjectWebhookSerializer.new(webhook).serialize
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
