# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Usage
              class Requests < Action
                params do
                  required(:project_id).filled(:string)
                  optional(:days).maybe(:integer, gteq?: 1, lteq?: 365)
                end

                def handle(request, response)
                  data = Backend::Analytics::APIUsage.new.call(
                    account: current_user(request).account,
                    project: project(request),
                    days: request.params[:days] || 30
                  ).value!

                  response.format = :json
                  response.body = data.to_json
                end
              end
            end
          end
        end
      end
    end
  end
end
