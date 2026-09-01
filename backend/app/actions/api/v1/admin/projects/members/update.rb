# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Members
              class Update < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:user_id).filled(:string)
                  required(:role).filled(:string, included_in?: %w[admin member])
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      errors: request.params.errors.to_h)
                  end

                  target_user = Backend::Models::User.first(
                    public_id: request.params[:user_id], account_id: project(request).account_id
                  )
                  return render_problem(response, status: 404, title: "Not Found", detail: "User not found") unless target_user

                  if target_user.owner?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      detail: "The account owner already has admin access everywhere - nothing to change")
                  end

                  membership = project(request).project_memberships_dataset.first(user_id: target_user.id)
                  return render_problem(response, status: 404, title: "Not Found", detail: "This user isn't a member of this project") unless membership

                  result = Backend::ProjectMemberships::Update.new.call(membership: membership, role: request.params[:role])

                  case result
                  in Success(updated)
                    response.format = :json
                    response.body = {
                      user_id: target_user.public_id, email: target_user.email,
                      project_role: updated.role, account_role: target_user.role
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
