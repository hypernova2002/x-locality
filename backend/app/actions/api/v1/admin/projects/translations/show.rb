# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class Show < Action
                def handle(request, response)
                  translation = project(request).translations_dataset.first(public_id: request.params[:id])
                  return render_problem(response, status: 404, title: "Not Found", detail: "Translation not found") unless translation

                  response.format = :json
                  response.body = Backend::Serializers::TranslationSerializer.new(translation).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
