# frozen_string_literal: true

# One row per LLM generation call (Backend::Llm::*Adapter#translate) - not
# per translation, since a single call can translate several items at once.
# Pure internal analytics log, never individually addressed via the API, so
# no public_id.
Sequel.migration do
  change do
    create_table(:llm_usage_events) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      foreign_key :locale_id, :locales, null: true, on_delete: :set_null

      column :provider, String, null: false
      column :model, String, null: false
      column :input_tokens, Integer, null: false
      column :output_tokens, Integer, null: false
      column :translation_count, Integer, null: false

      column :created_at, DateTime, null: false

      index [:project_id, :created_at]
    end
  end
end
