# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module ContextTags
              class Delete < Action
                def handle(request, response)
                  tag = project(request).context_tags_dataset.first(public_id: request.params[:id])
                  unless tag
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'Context tag not found')
                  end

                  Backend::ContextTags::Delete.new.call(context_tag: tag)
                  response.status = 204
                end
              end
            end
          end
        end
      end
    end
  end
end
