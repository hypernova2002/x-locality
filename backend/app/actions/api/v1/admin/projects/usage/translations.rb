# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Usage
              class Translations < Action
                params do
                  required(:project_id).filled(:string)
                  optional(:days).maybe(:integer, gteq?: 1, lteq?: 365)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  # No :days param means all-time - used by the Translations
                  # list page's header total; the usage graphs tab always
                  # sends an explicit day range.
                  data = Backend::Analytics::TranslationUsage.new.call(
                    project: project(request),
                    days: request.params[:days]
                  ).value!

                  response.format = :json
                  response.body = data.to_json
                end
              end
            end
          end
        end
      end
    end
  end
end
