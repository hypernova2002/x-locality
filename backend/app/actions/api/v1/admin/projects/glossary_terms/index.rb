# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module GlossaryTerms
              class Index < Action
                params do
                  required(:project_id).filled(:string)
                  optional(:offset).maybe(:integer, gteq?: 0)
                  optional(:limit).maybe(:integer, gteq?: 1, lteq?: 100)
                  optional(:search).maybe(:string)
                  optional(:source_language).maybe(:string)
                  optional(:target_locale).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  dataset = Backend::GlossaryTerms::List.new.call(
                    project: project(request), search: request.params[:search],
                    source_language_filter: request.params[:source_language],
                    target_locale_key: request.params[:target_locale]
                  ).value!
                  terms, total = paginate(dataset, request)

                  response.headers['X-Total-Count'] = total.to_s
                  response.format = :json
                  response.body = Backend::Serializers::GlossaryTermSerializer.new(terms).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
