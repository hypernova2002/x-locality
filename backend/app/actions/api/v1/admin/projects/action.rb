# frozen_string_literal: true

require "pagy"

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            class Action < Admin::Action
              before :load_project!

              private

              def load_project!(request, response)
                project = Backend::Models::Project.first(
                  public_id: request.params[:project_id],
                  account_id: current_user(request).account_id
                )
                return render_problem(response, status: 404, title: "Not Found", detail: "Project not found") unless project

                role = project.effective_role_for(current_user(request))
                # A project that exists but the user has no membership on
                # renders identically to one that doesn't exist - no
                # confirming its existence to someone without access.
                return render_problem(response, status: 404, title: "Not Found", detail: "Project not found") unless role

                request.env["backend.current_project"] = project
                request.env["backend.project_role"] = role
              end

              def project(request)
                request.env["backend.current_project"]
              end

              def project_role(request)
                request.env["backend.project_role"]
              end

              def require_project_admin!(request, response)
                return if project_role(request) == "admin"

                render_problem(response, status: 403, title: "Forbidden",
                  detail: "This action requires project admin access")
              end

              # Offset/limit pagination via Pagy::Offset, for the simple
              # single-dataset index actions (Locales, ContextTags,
              # APIKeys). Translations::ListGrouped paginates a derived
              # (distinct-key) dataset instead, so it uses Pagy directly.
              def paginate(dataset, request)
                limit = request.params[:limit] || 20
                offset = request.params[:offset] || 0
                page = (offset / limit) + 1

                pagy = Pagy::Offset.new(count: dataset.count, page: page, limit: limit)
                [pagy.records(dataset).all, pagy.count]
              end
            end
          end
        end
      end
    end
  end
end
