# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Invites
              class Create < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:email).filled(:string)
                  required(:role).filled(:string, included_in?: %w[admin member])
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::Invites::Create.new.call(
                    project: project(request), email: request.params[:email], role: request.params[:role],
                    invited_by_user: current_user(request)
                  )

                  case result
                  in Success(invite)
                    response.status = 201
                    response.format = :json
                    response.body = Backend::Serializers::InviteSerializer.new(invite).serialize
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
