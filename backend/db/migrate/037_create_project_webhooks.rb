# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:project_webhooks) do
      primary_key :id
      column :public_id, String, null: false, unique: true
      foreign_key :project_id, :projects, null: false, on_delete: :cascade

      column :url, String, null: false
      # Used to HMAC-SHA256 sign each delivery's body (X-Webhook-Signature),
      # so the receiver can verify a request actually came from us.
      column :secret, String, null: false
      column :event_types, "text[]", null: false, default: Sequel.lit("ARRAY[]::text[]")
      column :enabled, TrueClass, null: false, default: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:project_id]
    end
  end
end
