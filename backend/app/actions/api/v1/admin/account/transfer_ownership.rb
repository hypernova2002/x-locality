# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Account
            class TransferOwnership < Admin::Action
              before :require_owner!

              params do
                required(:email).filled(:string)
              end

              def handle(request, response)
                unless request.params.valid?
                  return render_problem(response, status: 422, title: "Unprocessable Entity",
                    errors: request.params.errors.to_h)
                end

                result = Backend::Accounts::TransferOwnership.new.call(
                  current_owner: current_user(request), new_owner_email: request.params[:email]
                )

                case result
                in Success(new_owner)
                  response.format = :json
                  response.body = Backend::Serializers::UserSerializer.new(new_owner).serialize
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
