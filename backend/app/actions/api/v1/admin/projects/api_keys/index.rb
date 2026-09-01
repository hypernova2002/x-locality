# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module APIKeys
              class Index < Action
                before :require_project_admin!

                params do
                  required(:project_id).filled(:string)
                  optional(:offset).maybe(:integer, gteq?: 0)
                  optional(:limit).maybe(:integer, gteq?: 1, lteq?: 100)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  keys, total = paginate(project(request).api_keys_dataset.order(:id), request)

                  response.headers['X-Total-Count'] = total.to_s
                  response.format = :json
                  response.body = Backend::Serializers::APIKeySerializer.new(keys).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
