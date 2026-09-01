# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Locales
              class Create < Action
                params do
                  required(:project_id).filled(:string)
                  required(:key).filled(:string)
                  required(:target_language).filled(:string)
                  optional(:style_tone_text).maybe(:string)
                  optional(:general_description).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::Locales::Create.new.call(
                    project: project(request),
                    key: request.params[:key],
                    target_language: request.params[:target_language],
                    style_tone_text: request.params[:style_tone_text],
                    general_description: request.params[:general_description]
                  )

                  case result
                  in Success(locale)
                    response.status = 201
                    response.format = :json
                    response.body = Backend::Serializers::LocaleSerializer.new(locale).serialize
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
