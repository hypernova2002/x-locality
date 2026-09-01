# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Account
            class Show < Admin::Action
              def handle(request, response)
                response.format = :json
                response.body = Backend::Serializers::AccountSerializer.new(current_user(request).account).serialize
              end
            end
          end
        end
      end
    end
  end
end
