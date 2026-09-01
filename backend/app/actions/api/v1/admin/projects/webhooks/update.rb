# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Webhooks
              class Update < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:id).filled(:string)
                  optional(:url).filled(:string)
                  optional(:event_types).array(:string)
                  optional(:enabled).filled(:bool)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      errors: request.params.errors.to_h)
                  end

                  webhook = project(request).project_webhooks_dataset.first(public_id: request.params[:id])
                  return render_problem(response, status: 404, title: "Not Found", detail: "Webhook not found") unless webhook

                  updates = request.params.to_h.slice(:url, :event_types, :enabled)
                  result = Backend::ProjectWebhooks::Update.new.call(project_webhook: webhook, updates: updates)

                  case result
                  in Success(updated_webhook)
                    response.format = :json
                    response.body = Backend::Serializers::ProjectWebhookSerializer.new(updated_webhook).serialize
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
