# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Invites
              class Index < Action
                before :require_project_admin!

                def handle(request, response)
                  invites = project(request).invites_dataset.where(accepted_at: nil).eager(:invited_by_user).all
                  response.format = :json
                  response.body = Backend::Serializers::InviteSerializer.new(invites).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
