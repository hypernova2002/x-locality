# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Invites
            # Public - the invited person doesn't have an account yet, so
            # this can't sit behind Admin::Action's JWT auth. Only exposes
            # what's needed to render the accept-invite screen.
            class Show < Backend::Action
              def handle(request, response)
                invite = Backend::Models::Invite.find_by_token(request.params[:token])
                unless invite
                  return render_problem(response, status: 404, title: 'Not Found',
                                                  detail: 'Invite not found')
                end

                if invite.accepted?
                  return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                  detail: 'This invite has already been accepted')
                end

                if invite.expired?
                  return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                  detail: 'This invite has expired')
                end

                response.format = :json
                response.body = {
                  email: invite.email,
                  role: invite.role,
                  project_name: invite.project.name,
                  invited_by_email: invite.invited_by_user&.email
                }.to_json
              end
            end
          end
        end
      end
    end
  end
end
