# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Account
            module Users
              class Delete < Admin::Action
                before :require_owner!

                def handle(request, response)
                  target = current_user(request).account.users_dataset.first(public_id: request.params[:id])
                  unless target
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'User not found')
                  end

                  result = Backend::Users::Delete.new.call(user: target)

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
