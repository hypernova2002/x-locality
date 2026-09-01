# frozen_string_literal: true

# Per-project role (admin/member) - the account owner is implicitly admin on
# every project in their account without needing a row here; everyone else
# needs an explicit membership to access a project at all.
Sequel.migration do
  change do
    create_table(:project_memberships) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      foreign_key :user_id, :users, null: false, on_delete: :cascade

      column :role, String, null: false # admin/member

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:project_id, :user_id], unique: true
      index :user_id
    end
  end
end
