# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          class Action < Backend::Action
            before :authenticate!

            private

            # Action instances are frozen and reused across requests, so
            # per-request state can't live in instance variables - it goes on
            # request.env instead, and every method that needs it takes
            # `request` explicitly.
            def authenticate!(request, response)
              token = bearer_token(request)
              return render_problem(response, status: 401, title: "Unauthorized", detail: "Missing bearer token") unless token

              payload = Backend::Jwt.decode(token, secret: Hanami.app["settings"].jwt_secret)
              return render_problem(response, status: 401, title: "Unauthorized", detail: "Invalid or expired token") unless payload

              user = Backend::Models::User[payload["user_id"]]
              return render_problem(response, status: 401, title: "Unauthorized", detail: "User no longer exists") unless user

              request.env["backend.current_user"] = user
            end

            def current_user(request)
              request.env["backend.current_user"]
            end

            def bearer_token(request)
              header = request.get_header("HTTP_AUTHORIZATION")
              return nil unless header&.start_with?("Bearer ")

              header.sub("Bearer ", "")
            end

            def require_owner!(request, response)
              return if current_user(request).owner?

              render_problem(response, status: 403, title: "Forbidden", detail: "This action requires the account owner")
            end
          end
        end
      end
    end
  end
end
