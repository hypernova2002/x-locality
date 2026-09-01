# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Invites
            class Accept < Backend::Action
              params do
                required(:token).filled(:string)
                required(:password).filled(:string, min_size?: 8)
              end

              def handle(request, response)
                unless request.params.valid?
                  return render_problem(response, status: 422, title: "Unprocessable Entity",
                    errors: request.params.errors.to_h)
                end

                result = Backend::Invites::Accept.new.call(
                  token: request.params[:token], password: request.params[:password]
                )

                case result
                in Success(user)
                  token = Backend::Jwt.encode(
                    { user_id: user.id },
                    secret: Hanami.app["settings"].jwt_secret,
                    ttl: Hanami.app["settings"].jwt_access_token_ttl
                  )

                  response.status = 201
                  response.format = :json
                  response.body = {
                    access_token: token,
                    user: { id: user.public_id, email: user.email, role: user.role, account_id: user.account.public_id }
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
