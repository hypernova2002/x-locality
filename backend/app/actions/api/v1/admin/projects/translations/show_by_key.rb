# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class ShowByKey < Action
                def handle(request, response)
                  records = project(request).translations_dataset.where(key: request.params[:key]).all
                  if records.empty?
                    return render_problem(response, status: 404, title: "Not Found",
                      detail: "No translations found for key '#{request.params[:key]}'")
                  end

                  usage_by_locale = usage_counts_by_locale(project(request), request.params[:key])
                  translations = Backend::Serializers::TranslationSerializer.new(records).serializable_hash.map do |t|
                    t.merge(usage: usage_by_locale.fetch(t[:locale],
                      { total_requests: 0, cache_hits: 0, llm_generations: 0 }))
                  end

                  response.format = :json
                  response.body = {
                    key: request.params[:key],
                    source_text: records.first.source_text,
                    locked: records.first.locked,
                    translations: translations
                  }.to_json
                end

                private

                def usage_counts_by_locale(project, key)
                  locale_keys = project.locales_dataset.select_hash(:id, :key)
                  rows = Backend::Models::TranslationUsageEvent
                    .where(project_id: project.id, key: key)
                    .group_and_count(:locale_id, :cached)
                    .all

                  counts = Hash.new { |h, k| h[k] = { total_requests: 0, cache_hits: 0, llm_generations: 0 } }
                  rows.each do |row|
                    locale_key = locale_keys[row[:locale_id]]
                    next unless locale_key

                    entry = counts[locale_key]
                    entry[:total_requests] += row[:count]
                    entry[row[:cached] ? :cache_hits : :llm_generations] += row[:count]
                  end
                  counts
                end
              end
            end
          end
        end
      end
    end
  end
end
