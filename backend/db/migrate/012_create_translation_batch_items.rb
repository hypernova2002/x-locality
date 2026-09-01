# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:translation_batch_items) do
      primary_key :id
      foreign_key :translation_batch_id, :translation_batches, null: false, on_delete: :cascade
      foreign_key :locale_id, :locales, null: false, on_delete: :cascade

      column :key, String, null: false
      column :source_text, String, text: true, null: false
      column :source_language, String
      column :context_tag_keys, "text[]", default: Sequel.lit("ARRAY[]::text[]")
      column :status, String, null: false, default: "pending" # pending/completed/failed
      column :translated_text, String, text: true
      column :error, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index :translation_batch_id
    end
  end
end
