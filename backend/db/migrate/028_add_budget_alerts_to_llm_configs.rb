# frozen_string_literal: true

# Budget alerts: an email + threshold percent the admin sets alongside the
# monthly limits, and a marker for which month the alert was last sent so a
# crossed threshold emails once per month rather than on every request.
Sequel.migration do
  change do
    alter_table(:llm_configs) do
      add_column :alert_email, String
      add_column :alert_threshold_percent, Integer
      add_column :alert_sent_for_month, String
    end
  end
end
