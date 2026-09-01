# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Locales
              class BulkTranslate < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  required(:id).filled(:string)
                  required(:keys).array(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  locale = project(request).locales_dataset.first(public_id: request.params[:id])
                  unless locale
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'Locale not found')
                  end

                  result = Backend::Locales::BulkTranslate.new.call(
                    project: project(request),
                    locale: locale,
                    keys: request.params[:keys],
                    unit_limit: Hanami.app['settings'].batch_translation_unit_limit
                  )

                  case result
                  in Success(data)
                    response.format = :json
                    response.body = data.to_json
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
