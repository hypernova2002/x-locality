# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class BulkDelete < Action
                params do
                  required(:project_id).filled(:string)
                  required(:keys).array(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      errors: request.params.errors.to_h)
                  end

                  result = Backend::Translations::BulkDelete.new.call(
                    project: project(request), keys: request.params[:keys]
                  )

                  response.format = :json
                  response.body = result.value!.to_json
                end
              end
            end
          end
        end
      end
    end
  end
end
