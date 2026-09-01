# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            class Index < Admin::Action
              def handle(request, response)
                user = current_user(request)
                projects = if user.owner?
                  Backend::Models::Project.where(account_id: user.account_id)
                else
                  member_project_ids = Backend::Models::ProjectMembership.where(user_id: user.id).select_map(:project_id)
                  Backend::Models::Project.where(account_id: user.account_id, id: member_project_ids)
                end.order(:name).all

                response.format = :json
                response.body = Backend::Serializers::ProjectSerializer.new(
                  projects, params: { current_user: user }
                ).serialize
              end
            end
          end
        end
      end
    end
  end
end
