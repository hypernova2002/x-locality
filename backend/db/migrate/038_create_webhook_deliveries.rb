# frozen_string_literal: true

# One row per delivery attempt (not per event) - a failed attempt followed
# by a successful Sidekiq retry shows the full history, not just the final
# outcome.
Sequel.migration do
  change do
    create_table(:webhook_deliveries) do
      primary_key :id
      foreign_key :project_webhook_id, :project_webhooks, null: false, on_delete: :cascade

      column :event_type, String, null: false
      column :payload, String, text: true, null: false
      column :response_status, Integer
      column :error_message, String, text: true
      column :success, TrueClass, null: false

      column :created_at, DateTime, null: false

      index [:project_webhook_id, :created_at]
    end
  end
end
