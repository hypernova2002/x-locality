# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Members
              # Admin-only - the account owner is synthesized into the list
              # even though they have no explicit membership row.
              class Index < Action
                before :require_project_admin!

                def handle(request, response)
                  members = []

                  owner = project(request).account.owner
                  if owner
                    members << { user_id: owner.public_id, email: owner.email, project_role: 'admin',
                                 account_role: 'owner' }
                  end

                  project(request).project_memberships_dataset.eager(:user).all.each do |m|
                    members << {
                      user_id: m.user.public_id, email: m.user.email,
                      project_role: m.role, account_role: m.user.role
                    }
                  end

                  response.format = :json
                  response.body = members.to_json
                end
              end
            end
          end
        end
      end
    end
  end
end
