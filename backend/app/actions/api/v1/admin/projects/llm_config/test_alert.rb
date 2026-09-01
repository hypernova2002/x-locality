# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmConfig
              class TestAlert < Action
                before :require_project_admin!

                def handle(request, response)
                  result = Backend::LlmConfigs::SendTestAlert.new.call(project: project(request))

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
