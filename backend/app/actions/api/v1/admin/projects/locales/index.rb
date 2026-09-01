# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Locales
              class Index < Action
                params do
                  required(:project_id).filled(:string)
                  optional(:offset).maybe(:integer, gteq?: 0)
                  optional(:limit).maybe(:integer, gteq?: 1, lteq?: 100)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      errors: request.params.errors.to_h)
                  end

                  locales, total = paginate(project(request).locales_dataset.order(:key), request)

                  response.headers["X-Total-Count"] = total.to_s
                  response.format = :json
                  response.body = Backend::Serializers::LocaleSerializer.new(locales).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
