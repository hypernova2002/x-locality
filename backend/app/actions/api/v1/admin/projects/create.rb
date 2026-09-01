# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            class Create < Admin::Action
              params do
                required(:name).filled(:string)
              end

              def handle(request, response)
                unless request.params.valid?
                  return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                  errors: request.params.errors.to_h)
                end

                result = Backend::Projects::Create.new.call(
                  account: current_user(request).account,
                  name: request.params[:name],
                  created_by_user: current_user(request)
                )

                case result
                in Success(project)
                  response.status = 201
                  response.format = :json
                  response.body = Backend::Serializers::ProjectSerializer.new(
                    project, params: { current_user: current_user(request) }
                  ).serialize
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
