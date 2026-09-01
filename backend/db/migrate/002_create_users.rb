# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      foreign_key :account_id, :accounts, null: false, on_delete: :cascade

      column :email, String, null: false
      column :password_digest, String, null: false
      column :role, String, null: false, default: "owner" # owner/admin/member

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index :email, unique: true
    end
  end
end
