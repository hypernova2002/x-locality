# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module ContextTags
              class Update < Action
                params do
                  required(:project_id).filled(:string)
                  required(:id).filled(:string)
                  optional(:key).filled(:string)
                  optional(:description).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: "Unprocessable Entity",
                      errors: request.params.errors.to_h)
                  end

                  tag = project(request).context_tags_dataset.first(public_id: request.params[:id])
                  return render_problem(response, status: 404, title: "Not Found", detail: "Context tag not found") unless tag

                  updates = request.params.to_h.slice(:key, :description)
                  result = Backend::ContextTags::Update.new.call(context_tag: tag, updates: updates)

                  case result
                  in Success(updated_tag)
                    response.format = :json
                    response.body = Backend::Serializers::ContextTagSerializer.new(updated_tag).serialize
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
