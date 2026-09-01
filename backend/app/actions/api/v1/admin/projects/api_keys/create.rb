# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module APIKeys
              class Create < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:name).filled(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      errors: request.params.errors.to_h)
                  end

                  api_key = Backend::Models::APIKey.generate(
                    project: project(request),
                    name: request.params[:name],
                    created_by_user: current_user(request)
                  )

                  response.status = 201
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
