# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Translations
          class Show < API::V1::Action
            def handle(request, response)
              records = current_project(request).translations_dataset.where(key: request.params[:key]).all

              if records.empty?
                return render_problem(response, status: 404, title: "Not Found",
                  detail: "No translations found for key '#{request.params[:key]}'")
              end

              response.format = :json
              response.body = Backend::Serializers::TranslationSerializer.new(records).serialize
            end
          end
        end
      end
    end
  end
end
