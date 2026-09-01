# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:translation_versions) do
      primary_key :id
      foreign_key :translation_id, :translations, null: false, on_delete: :cascade
      foreign_key :changed_by_user_id, :users, null: true, on_delete: :set_null

      column :previous_value, String, text: true
      column :new_value, String, text: true
      column :changed_by_type, String, null: false # llm/user

      column :created_at, DateTime, null: false

      index :translation_id
    end
  end
end
