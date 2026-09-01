# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module GlossaryTerms
              class Delete < Action
                def handle(request, response)
                  term = project(request).glossary_terms_dataset.first(public_id: request.params[:id])
                  unless term
                    return render_problem(response, status: 404, title: 'Not Found', detail: 'Glossary term not found')
                  end

                  Backend::GlossaryTerms::Delete.new.call(glossary_term: term)
                  response.status = 204
                end
              end
            end
          end
        end
      end
    end
  end
end
