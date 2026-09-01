# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module APIKeys
              class Revoke < Action
                before :require_project_admin!

                def handle(request, response)
                  api_key = project(request).api_keys_dataset.first(public_id: request.params[:id])
                  unless api_key
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'API key not found')
                  end

                  api_key.update(revoked_at: Time.now)

                  response.format = :json
                  response.body = Backend::Serializers::APIKeySerializer.new(api_key).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
