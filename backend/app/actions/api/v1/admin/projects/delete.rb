# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            class Delete < Action
              before :require_project_admin!

              def handle(request, response)
                project(request).destroy
                response.status = 204
              end
            end
          end
        end
      end
    end
  end
end
