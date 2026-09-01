# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Translations
          class Create < API::V1::Action
            # Keys are used directly in URLs (GET /translations/:key), so
            # they're restricted to what's safe there unencoded.
            KEY_FORMAT = /\A[a-zA-Z0-9_-]+\z/

            params do
              required(:target_locales).array(:string)
              required(:items).array(:hash) do
                required(:key).filled(:string, format?: KEY_FORMAT)
                required(:source_text).filled(:string)
                optional(:source_language).maybe(:string)
                optional(:context).array(:string)
              end
            end

            def handle(request, response)
              unless request.params.valid?
                return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                errors: request.params.errors.to_h)
              end

              project = current_project(request)
              result = Backend::Translations::Create.new.call(
                project: project,
                target_locale_keys: request.params[:target_locales],
                items: request.params[:items],
                unit_limit: Hanami.app['settings'].sync_translation_unit_limit
              )

              record_usage_events(project, result.value!) if result.success?

              case result
              in Success(*body)
                response.format = :json
                response.body = body.to_json
              in Failure[code, detail]
                render_failure(response, code, detail)
              end
            end

            private

            # Only this endpoint - not admin regenerate/bulk_regenerate,
            # which force a fresh LLM call regardless of cache state and
            # aren't a genuine "was this translation requested" signal.
            def record_usage_events(project, translations_response)
              locale_ids = project.locales_dataset.select_hash(:key, :id)
              now = Time.now
              rows = translations_response.flat_map do |item|
                item[:translations].map do |t|
                  { project_id: project.id, locale_id: locale_ids[t[:locale]], key: item[:key],
                    cached: t[:cached], created_at: now }
                end
              end
              Backend::Models::TranslationUsageEvent.multi_insert(rows) unless rows.empty?
            end
          end
        end
      end
    end
  end
end
