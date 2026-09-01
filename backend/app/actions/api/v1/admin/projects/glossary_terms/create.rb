# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module GlossaryTerms
              class Create < Action
                params do
                  required(:project_id).filled(:string)
                  required(:source_term).filled(:string)
                  required(:source_language).filled(:string)
                  required(:target_term).filled(:string)
                  optional(:target_locale_key).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::GlossaryTerms::Create.new.call(
                    project: project(request),
                    source_term: request.params[:source_term],
                    source_language: request.params[:source_language],
                    target_term: request.params[:target_term],
                    target_locale_key: request.params[:target_locale_key]
                  )

                  case result
                  in Success(term)
                    response.status = 201
                    response.format = :json
                    response.body = Backend::Serializers::GlossaryTermSerializer.new(term).serialize
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
