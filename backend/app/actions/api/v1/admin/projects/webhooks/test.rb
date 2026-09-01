# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Webhooks
              class Test < Action
                before :require_project_admin!

                def handle(request, response)
                  webhook = project(request).project_webhooks_dataset.first(public_id: request.params[:id])
                  return render_problem(response, status: 404, title: "Not Found", detail: "Webhook not found") unless webhook

                  result = Backend::ProjectWebhooks::SendTest.new.call(project_webhook: webhook)

                  case result
                  in Success(_)
                    response.status = 204
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
