# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Webhooks
              class Delete < Action
                before :require_project_admin!

                def handle(request, response)
                  webhook = project(request).project_webhooks_dataset.first(public_id: request.params[:id])
                  unless webhook
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'Webhook not found')
                  end

                  Backend::ProjectWebhooks::Delete.new.call(project_webhook: webhook)
                  response.status = 204
                end
              end
            end
          end
        end
      end
    end
  end
end
