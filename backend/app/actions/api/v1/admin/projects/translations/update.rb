# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class Update < Action
                params do
                  required(:project_id).filled(:string)
                  required(:id).filled(:string)
                  required(:translated_text).filled(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  translation = project(request).translations_dataset.first(public_id: request.params[:id])
                  unless translation
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'Translation not found')
                  end

                  result = Backend::Translations::Update.new.call(
                    translation: translation,
                    translated_text: request.params[:translated_text],
                    changed_by_user: current_user(request)
                  )

                  case result
                  in Success(updated)
                    response.format = :json
                    response.body = Backend::Serializers::TranslationSerializer.new(updated).serialize
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
