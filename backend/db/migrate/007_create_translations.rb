# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:translations) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      foreign_key :locale_id, :locales, null: false, on_delete: :cascade

      column :key, String, null: false # client-specified, stable per project+locale
      column :source_text, String, text: true, null: false
      column :source_language, String
      column :detected_language, String
      column :translated_text, String, text: true
      column :status, String, null: false, default: "pending" # pending/completed/failed
      column :generated_by, String, null: false, default: "llm" # llm/user
      column :model_used, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:project_id, :key, :locale_id], unique: true
      index [:project_id, :updated_at]
    end
  end
end
