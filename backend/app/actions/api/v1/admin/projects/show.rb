# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            class Show < Action
              def handle(request, response)
                response.format = :json
                response.body = Backend::Serializers::ProjectSerializer.new(
                  project(request), params: { current_user: current_user(request) }
                ).serialize
              end
            end
          end
        end
      end
    end
  end
end
