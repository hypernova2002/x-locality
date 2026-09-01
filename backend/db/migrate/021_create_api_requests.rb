# frozen_string_literal: true

# One row per authenticated call to the API-key surface (POST/GET
# /api/v1/translations*) - powers the "how often was the API used" view.
# Pure internal analytics log, no public_id.
Sequel.migration do
  change do
    create_table(:api_requests) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      foreign_key :api_key_id, :api_keys, null: true, on_delete: :set_null

      column :http_method, String, null: false
      column :path, String, null: false
      column :status, Integer, null: false

      column :created_at, DateTime, null: false

      index [:project_id, :created_at]
    end
  end
end
