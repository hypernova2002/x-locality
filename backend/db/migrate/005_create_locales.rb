# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:locales) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade

      column :key, String, null: false # e.g. "fr", "fr-casual"
      column :target_language, String, null: false # ISO code, e.g. "fr"
      column :style_tone_text, String, text: true
      column :general_description, String, text: true
      column :system, TrueClass, null: false, default: false # seeded ISO locales - not deletable

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:project_id, :key], unique: true
    end
  end
end
