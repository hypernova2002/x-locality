# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:context_tags) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade

      column :key, String, null: false # e.g. "fruit", "brand"
      column :description, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:project_id, :key], unique: true
    end
  end
end
