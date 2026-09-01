# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:api_keys) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      foreign_key :created_by_user_id, :users, null: true, on_delete: :set_null

      column :name, String, null: false
      column :key_digest, String, null: false
      column :last_used_at, DateTime
      column :revoked_at, DateTime

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index :key_digest, unique: true
      index :project_id
    end
  end
end
