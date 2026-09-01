# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class Regenerate < Action
                def handle(request, response)
                  translation = project(request).translations_dataset.first(public_id: request.params[:id])
                  return render_problem(response, status: 404, title: "Not Found", detail: "Translation not found") unless translation

                  result = Backend::Translations::Create.new.call(
                    project: project(request),
                    target_locale_keys: [translation.locale.key],
                    items: [{
                      key: translation.key,
                      source_text: translation.source_text,
                      source_language: translation.source_language,
                      context: translation.context_tags.map(&:key)
                    }],
                    unit_limit: 1,
                    force: true
                  )

                  case result
                  in Success(_body)
                    updated = project(request).translations_dataset.first(public_id: request.params[:id])
                    response.format = :json
                    response.body = Backend::Serializers::TranslationSerializer.new(updated).serialize
                  in Failure[code, detail]
                    render_failure(response, code, detail)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
