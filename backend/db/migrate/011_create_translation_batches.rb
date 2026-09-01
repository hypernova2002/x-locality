# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:translation_batches) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade

      column :status, String, null: false, default: "pending" # pending/processing/completed/partial/failed
      column :unit_count, Integer, null: false
      column :completed_count, Integer, null: false, default: 0

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
      column :completed_at, DateTime

      index :project_id
    end
  end
end
