# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            class Update < Action
              before :require_project_admin!

              params do
                required(:project_id).filled(:string)
                optional(:name).filled(:string)
              end

              def handle(request, response)
                unless request.params.valid?
                  return render_problem(response, status: 422, title: "Unprocessable Entity",
                    errors: request.params.errors.to_h)
                end

                updates = request.params.to_h.slice(:name)
                result = Backend::Projects::Update.new.call(project: project(request), updates: updates)

                case result
                in Success(project)
                  response.format = :json
                  response.body = Backend::Serializers::ProjectSerializer.new(
                    project, params: { current_user: current_user(request) }
                  ).serialize
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
