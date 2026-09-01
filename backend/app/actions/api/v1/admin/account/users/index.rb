# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Account
            module Users
              class Index < Admin::Action
                def handle(request, response)
                  users = current_user(request).account.users_dataset.order(:email).all
                  response.format = :json
                  response.body = Backend::Serializers::UserSerializer.new(users).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
