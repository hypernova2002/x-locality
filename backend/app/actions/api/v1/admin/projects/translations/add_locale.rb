# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class AddLocale < Action
                params do
                  required(:project_id).filled(:string)
                  required(:key).filled(:string)
                  required(:locale).filled(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::Translations::AddLocale.new.call(
                    project: project(request), key: request.params[:key], locale_key: request.params[:locale]
                  )

                  case result
                  in Success(_body)
                    locale = project(request).locales_dataset.first(key: request.params[:locale])
                    created = project(request).translations_dataset.first(key: request.params[:key],
                                                                          locale_id: locale.id)
                    response.status = 201
                    response.format = :json
                    response.body = Backend::Serializers::TranslationSerializer.new(created).serialize
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
