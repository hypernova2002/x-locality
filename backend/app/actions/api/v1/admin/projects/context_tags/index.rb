# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module ContextTags
              class Index < Action
                params do
                  required(:project_id).filled(:string)
                  optional(:offset).maybe(:integer, gteq?: 0)
                  optional(:limit).maybe(:integer, gteq?: 1, lteq?: 100)
                  optional(:search).maybe(:string)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  dataset = Backend::ContextTags::List.new.call(
                    project: project(request), search: request.params[:search]
                  ).value!
                  tags, total = paginate(dataset, request)

                  response.headers['X-Total-Count'] = total.to_s
                  response.format = :json
                  response.body = Backend::Serializers::ContextTagSerializer.new(tags).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
