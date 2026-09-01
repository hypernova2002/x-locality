# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        class Action < Backend::Action
          before :authenticate!
          after :log_request!

          private

          def authenticate!(request, response)
            token = bearer_token(request)
            return render_problem(response, status: 401, title: 'Unauthorized', detail: 'Missing API key') unless token

            api_key = Backend::Models::APIKey.authenticate(token)
            unless api_key
              return render_problem(response, status: 401, title: 'Unauthorized',
                                              detail: 'Invalid or revoked API key')
            end

            api_key.update(last_used_at: Time.now)
            request.env['backend.current_project'] = api_key.project
            request.env['backend.current_api_key'] = api_key
          end

          # Only logs authenticated requests - an invalid/missing API key
          # never resolves a project to attribute the request to.
          def log_request!(request, response)
            project = request.env['backend.current_project']
            return unless project

            Backend::Models::APIRequest.create(
              project_id: project.id,
              api_key_id: request.env['backend.current_api_key']&.id,
              http_method: request.request_method,
              path: request.path,
              status: response.status,
              created_at: Time.now
            )
          end

          def current_project(request)
            request.env['backend.current_project']
          end

          def bearer_token(request)
            header = request.get_header('HTTP_AUTHORIZATION')
            return nil unless header&.start_with?('Bearer ')

            header.sub('Bearer ', '')
          end
        end
      end
    end
  end
end
