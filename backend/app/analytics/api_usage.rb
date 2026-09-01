# frozen_string_literal: true

module Backend
  module Analytics
    # project: nil means account-wide (every project on the account).
    class APIUsage < Backend::Operation
      def call(account:, project: nil, days: 30)
        since = Date.today - days
        requests = scoped(Backend::Models::APIRequest, account, project).where { created_at >= since }
        usage_events = scoped(Backend::Models::LlmUsageEvent, account, project).where(success: true)
          .where { created_at >= since }
        translations = scoped(Backend::Models::Translation, account, project).where { updated_at >= since }

        {
          total_requests: requests.count,
          successful_requests: requests.where { status < 400 }.count,
          failed_requests: requests.where { status >= 400 }.count,
          total_translations: usage_events.sum(:translation_count) || 0,
          translations_completed: translations.where(status: "completed").count,
          translations_failed: translations.where(status: "failed").count,
          by_day: daily_request_counts(requests)
        }
      end

      private

      def scoped(model, account, project)
        project ? model.where(project_id: project.id) : model.where(project_id: account.projects_dataset.select(:id))
      end

      def daily_request_counts(dataset)
        dataset
          .select(Sequel.function(:date_trunc, "day", :created_at).as(:day), Sequel.function(:count, :id).as(:count))
          .group_by(Sequel.function(:date_trunc, "day", :created_at))
          .order(:day)
          .all
          .map { |row| { date: row[:day].strftime("%Y-%m-%d"), count: row[:count] } }
      end
    end
  end
end
