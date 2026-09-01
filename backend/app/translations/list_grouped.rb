# frozen_string_literal: true

require 'pagy'

module Backend
  module Translations
    # Admin-only view of translations, grouped by client key (one entry per
    # key, with every locale's status/translation nested inside) - distinct
    # from the flat, per-(key,locale)-row Translations::List used by the
    # API-key surface, which external integrations may depend on as-is.
    class ListGrouped < Backend::Operation
      def call(project:, search: nil, key: nil, status: nil, source_language: nil, target_language: nil,
               llm_provider: nil, llm_model: nil, locked: nil, offset: 0, limit: 20)
        matching = filtered_dataset(project, search:, key:, status:, source_language:, target_language:,
                                             llm_provider:, llm_model:, locked:)

        keys_dataset = matching.select(:key).distinct.order(:key)
        page = (offset / limit) + 1
        pagy = Pagy::Offset.new(count: keys_dataset.count, page: page, limit: limit)

        keys_page = pagy.records(keys_dataset).map { |row| row[:key] }

        return { groups: [], total: pagy.count } if keys_page.empty?

        rows = project.translations_dataset.where(key: keys_page).order(:id).all
        locales_by_id = project.locales_dataset.where(id: rows.map(&:locale_id).uniq).all.to_h { |l| [l.id, l] }
        rows_by_key = rows.group_by(&:key)
        usage_by_key = usage_counts(project, keys_page)

        groups = keys_page.map do |k|
          translations = rows_by_key.fetch(k, [])
          source = translations.first
          {
            key: k,
            source_text: source&.source_text,
            source_language: source&.source_language || source&.detected_language,
            locked: source&.locked || false,
            translations: translations.map { |t| decorate(t, locales_by_id[t.locale_id]) },
            usage: usage_by_key.fetch(k, { total_requests: 0, cache_hits: 0, llm_generations: 0 })
          }
        end

        { groups: groups, total: pagy.count }
      end

      private

      def filtered_dataset(project, search:, key:, status:, source_language:, target_language:, llm_provider:,
                           llm_model:, locked:)
        dataset = project.translations_dataset

        dataset = dataset.where(Sequel.ilike(:source_text, "%#{search}%")) if search
        dataset = dataset.where(Sequel.ilike(:key, "%#{key}%")) if key
        dataset = dataset.where(status:) if status
        dataset = dataset.where(Sequel.ilike(:model_used, "%#{llm_model}%")) if llm_model
        dataset = dataset.where(llm_provider:) if llm_provider
        dataset = dataset.where(locked:) unless locked.nil?

        if source_language
          dataset = dataset.where(
            Sequel.|({ source_language: }, { detected_language: source_language })
          )
        end

        if target_language
          locale = project.locales_dataset.first(key: target_language)
          dataset = locale ? dataset.where(locale_id: locale.id) : dataset.where(Sequel.lit('false'))
        end

        dataset
      end

      def usage_counts(project, keys)
        rows = Backend::Models::TranslationUsageEvent
               .where(project_id: project.id, key: keys)
               .group_and_count(:key, :cached)
               .all

        counts = Hash.new { |h, k| h[k] = { total_requests: 0, cache_hits: 0, llm_generations: 0 } }
        rows.each do |row|
          entry = counts[row[:key]]
          entry[:total_requests] += row[:count]
          entry[row[:cached] ? :cache_hits : :llm_generations] += row[:count]
        end
        counts
      end

      def decorate(translation, locale)
        {
          id: translation.public_id,
          locale: locale.key,
          status: translation.status,
          translated_text: translation.translated_text,
          generated_by: translation.generated_by,
          llm_provider: translation.llm_provider,
          model_used: translation.model_used,
          updated_at: translation.updated_at
        }
      end
    end
  end
end
