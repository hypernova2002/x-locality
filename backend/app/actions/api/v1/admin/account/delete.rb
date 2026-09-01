# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Account
            class Delete < Admin::Action
              before :require_owner!

              def handle(request, response)
                Backend::Accounts::Delete.new.call(account: current_user(request).account)
                response.status = 204
              end
            end
          end
        end
      end
    end
  end
end
