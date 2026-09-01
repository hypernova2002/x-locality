# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Members
              class Delete < Action
                before :require_project_admin!

                def handle(request, response)
                  target_user = Backend::Models::User.first(
                    public_id: request.params[:user_id], account_id: project(request).account_id
                  )
                  unless target_user
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'User not found')
                  end

                  if target_user.owner?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    detail: "The account owner can't be removed from a project")
                  end

                  membership = project(request).project_memberships_dataset.first(user_id: target_user.id)
                  unless membership
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: "This user isn't a member of this project")
                  end

                  Backend::ProjectMemberships::Delete.new.call(membership: membership)
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
