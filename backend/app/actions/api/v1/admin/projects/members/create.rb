# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Members
              class Create < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:email).filled(:string)
                  required(:role).filled(:string, included_in?: %w[admin member])
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      errors: request.params.errors.to_h)
                  end

                  result = Backend::ProjectMemberships::Create.new.call(
                    project: project(request), email: request.params[:email], role: request.params[:role]
                  )

                  case result
                  in Success(membership)
                    response.status = 201
                    response.format = :json
                    response.body = {
                      user_id: membership.user.public_id, email: membership.user.email,
                      project_role: membership.role, account_role: membership.user.role
                    }.to_json
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
