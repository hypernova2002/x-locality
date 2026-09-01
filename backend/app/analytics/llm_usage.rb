# frozen_string_literal: true

module Backend
  module Analytics
    # project: nil means account-wide (every project on the account).
    class LlmUsage < Backend::Operation
      def call(account:, project: nil, days: 30)
        since = Date.today - days
        rows = scoped(account, project).where { created_at >= since }.all
        successful = rows.select(&:success)

        {
          total_input_tokens: successful.sum(&:input_tokens),
          total_output_tokens: successful.sum(&:output_tokens),
          total_cost: sum_cost(successful),
          successful_calls: successful.size,
          failed_calls: rows.size - successful.size,
          avg_latency_ms: avg_latency(successful),
          by_day: daily_breakdown(rows),
          by_provider_model: provider_model_breakdown(rows),
          recent_failures: recent_failures(rows)
        }
      end

      private

      def avg_latency(rows)
        durations = rows.filter_map(&:duration_ms)
        durations.empty? ? nil : (durations.sum / durations.size.to_f).round
      end

      def recent_failures(rows)
        rows.reject(&:success).sort_by(&:created_at).last(10).reverse.map do |r|
          { provider: r.provider, model: r.llm_model, error_message: r.error_message, created_at: r.created_at }
        end
      end

      def scoped(account, project)
        if project
          Backend::Models::LlmUsageEvent.where(project_id: project.id)
        else
          Backend::Models::LlmUsageEvent.where(project_id: account.projects_dataset.select(:id))
        end
      end

      def sum_cost(rows)
        costs = rows.filter_map { |r| Backend::Llm::Pricing.cost(model: r.llm_model, input_tokens: r.input_tokens, output_tokens: r.output_tokens) }
        costs.empty? ? nil : costs.sum
      end

      def daily_breakdown(rows)
        rows
          .group_by { |r| r.created_at.to_date }
          .sort_by { |date, _| date }
          .map do |date, group|
            successful = group.select(&:success)
            {
              date: date.strftime("%Y-%m-%d"),
              input_tokens: successful.sum(&:input_tokens),
              output_tokens: successful.sum(&:output_tokens),
              failed_calls: group.size - successful.size
            }
          end
      end

      def provider_model_breakdown(rows)
        rows.group_by { |r| [r.provider, r.llm_model] }.map do |(provider, model), group|
          successful = group.select(&:success)
          input_tokens = successful.sum(&:input_tokens)
          output_tokens = successful.sum(&:output_tokens)
          {
            provider: provider,
            model: model,
            input_tokens: input_tokens,
            output_tokens: output_tokens,
            translation_count: successful.sum(&:translation_count),
            successful_calls: successful.size,
            failed_calls: group.size - successful.size,
            avg_latency_ms: avg_latency(successful),
            cost: Backend::Llm::Pricing.cost(model: model, input_tokens: input_tokens, output_tokens: output_tokens)
          }
        end
      end
    end
  end
end
