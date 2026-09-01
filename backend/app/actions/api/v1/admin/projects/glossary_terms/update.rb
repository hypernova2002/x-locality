# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module GlossaryTerms
              class Update < Action
                params do
                  required(:project_id).filled(:string)
                  required(:id).filled(:string)
                  optional(:source_term).filled(:string)
                  optional(:source_language).filled(:string)
                  optional(:target_term).filled(:string)
                  optional(:target_locale_key).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  term = project(request).glossary_terms_dataset.first(public_id: request.params[:id])
                  unless term
                    return render_problem(response, status: 404, title: 'Not Found', detail: 'Glossary term not found')
                  end

                  updates = request.params.to_h.slice(:source_term, :source_language, :target_term, :target_locale_key)
                  result = Backend::GlossaryTerms::Update.new.call(glossary_term: term, updates: updates)

                  case result
                  in Success(updated_term)
                    response.format = :json
                    response.body = Backend::Serializers::GlossaryTermSerializer.new(updated_term).serialize
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
