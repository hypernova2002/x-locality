# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class Index < Action
                params do
                  required(:project_id).filled(:string)
                  optional(:search).maybe(:string)
                  optional(:key).maybe(:string)
                  optional(:status).maybe(:string)
                  optional(:source_language).maybe(:string)
                  optional(:target_language).maybe(:string)
                  optional(:llm_provider).maybe(:string)
                  optional(:llm_model).maybe(:string)
                  optional(:locked).maybe(:bool)
                  optional(:offset).maybe(:integer, gteq?: 0)
                  optional(:limit).maybe(:integer, gteq?: 1, lteq?: 100)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::Translations::ListGrouped.new.call(
                    project: project(request),
                    search: request.params[:search],
                    key: request.params[:key],
                    status: request.params[:status],
                    source_language: request.params[:source_language],
                    target_language: request.params[:target_language],
                    llm_provider: request.params[:llm_provider],
                    llm_model: request.params[:llm_model],
                    locked: request.params[:locked],
                    offset: request.params[:offset] || 0,
                    limit: request.params[:limit] || 20
                  )

                  case result
                  in Success(data)
                    response.headers['X-Total-Count'] = data[:total].to_s
                    response.format = :json
                    response.body = data[:groups].to_json
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
