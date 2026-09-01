# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmConfig
              class Show < Action
                before :require_project_admin!

                def handle(request, response)
                  config = project(request).llm_config
                  return render_problem(response, status: 404, title: "Not Found", detail: "LLM config not found") unless config

                  response.format = :json
                  response.body = Backend::Serializers::LlmConfigSerializer.new(config).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
