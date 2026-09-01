# frozen_string_literal: true

module Backend
  module Analytics
    # Unlike Api/LlmUsage, there's no account-wide mode - a usage event only
    # makes sense scoped to the project whose translations it's about.
    # days: nil means all-time (used for the Translations list page's
    # header total, distinct from the day-windowed graphs tab).
    class TranslationUsage < Backend::Operation
      def call(project:, days: 30)
        scope = Backend::Models::TranslationUsageEvent.where(project_id: project.id)
        scope = scope.where { created_at >= (Date.today - days) } if days
        rows = scope.all

        cache_hits = rows.count(&:cached)

        {
          total_requests: rows.size,
          cache_hits: cache_hits,
          llm_generations: rows.size - cache_hits,
          by_day: daily_breakdown(rows)
        }
      end

      private

      def daily_breakdown(rows)
        rows
          .group_by { |r| r.created_at.to_date }
          .sort_by { |date, _| date }
          .map do |date, group|
            cache_hits = group.count(&:cached)
            {
              date: date.strftime('%Y-%m-%d'),
              total_requests: group.size,
              cache_hits: cache_hits,
              llm_generations: group.size - cache_hits
            }
          end
      end
    end
  end
end
