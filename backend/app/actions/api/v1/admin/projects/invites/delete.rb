# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Invites
              class Delete < Action
                before :require_project_admin!

                def handle(request, response)
                  invite = project(request).invites_dataset.first(public_id: request.params[:id])
                  return render_problem(response, status: 404, title: "Not Found", detail: "Invite not found") unless invite

                  Backend::Invites::Delete.new.call(invite: invite)
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
