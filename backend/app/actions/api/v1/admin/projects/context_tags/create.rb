# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module ContextTags
              class Create < Action
                params do
                  required(:project_id).filled(:string)
                  required(:key).filled(:string)
                  optional(:description).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  result = Backend::ContextTags::Create.new.call(
                    project: project(request),
                    key: request.params[:key],
                    description: request.params[:description]
                  )

                  case result
                  in Success(tag)
                    response.status = 201
                    response.format = :json
                    response.body = Backend::Serializers::ContextTagSerializer.new(tag).serialize
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
