# frozen_string_literal: true

# One row per (key, locale) requested through the external translation API
# (Backend::Actions::API::V1::Translations::Create only - not admin
# regenerate/bulk_regenerate, which force a fresh LLM call and aren't a
# genuine "was this translation requested" signal). Pure internal analytics
# log, never individually addressed via the API, so no public_id.
Sequel.migration do
  change do
    create_table(:translation_usage_events) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      foreign_key :locale_id, :locales, null: true, on_delete: :set_null

      column :key, String, null: false
      column :cached, TrueClass, null: false

      column :created_at, DateTime, null: false

      index [:project_id, :key]
      index [:project_id, :created_at]
    end
  end
end
