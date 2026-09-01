# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Locales
              class Update < Action
                params do
                  required(:project_id).filled(:string)
                  required(:id).filled(:string)
                  optional(:style_tone_text).maybe(:string)
                  optional(:general_description).maybe(:string)
                  optional(:target_language).filled(:string)
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

                  updates = request.params.to_h.slice(:style_tone_text, :general_description, :target_language)
                  result = Backend::Locales::Update.new.call(locale: locale, updates: updates)

                  case result
                  in Success(updated_locale)
                    response.format = :json
                    response.body = Backend::Serializers::LocaleSerializer.new(updated_locale).serialize
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
