# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmProviderConfigs
              class Delete < Action
                before :require_project_admin!

                def handle(request, response)
                  config = project(request).llm_provider_configs_dataset.first(public_id: request.params[:id])
                  unless config
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'LLM provider config not found')
                  end

                  Backend::LlmProviderConfigs::Delete.new.call(config: config)
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
