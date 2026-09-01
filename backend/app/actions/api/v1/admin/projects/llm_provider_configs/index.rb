# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module LlmProviderConfigs
              class Index < Action
                before :require_project_admin!

                def handle(request, response)
                  configs = project(request).llm_provider_configs_dataset.order(:name).all
                  response.format = :json
                  response.body = Backend::Serializers::LlmProviderConfigSerializer.new(configs).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
