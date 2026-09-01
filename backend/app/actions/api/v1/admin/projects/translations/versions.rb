# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class Versions < Action
                def handle(request, response)
                  translation = project(request).translations_dataset.first(public_id: request.params[:id])
                  unless translation
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'Translation not found')
                  end

                  versions = translation.versions_dataset.order(:id).all

                  response.format = :json
                  response.body = Backend::Serializers::TranslationVersionSerializer.new(versions).serialize
                end
              end
            end
          end
        end
      end
    end
  end
end
