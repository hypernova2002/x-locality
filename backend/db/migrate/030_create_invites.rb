# frozen_string_literal: true

# An invite grants a specific project + role to an email address that
# doesn't have an account user yet. token_digest follows the same
# hash-only-at-rest pattern as api_keys.key_digest - the plaintext token
# only ever exists in the email link.
Sequel.migration do
  change do
    create_table(:invites) do
      primary_key :id
      column :public_id, String, null: false, unique: true
      foreign_key :account_id, :accounts, null: false, on_delete: :cascade
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      foreign_key :invited_by_user_id, :users, null: true, on_delete: :set_null

      column :email, String, null: false
      column :role, String, null: false # admin/member
      column :token_digest, String, null: false
      column :expires_at, DateTime, null: false
      column :accepted_at, DateTime

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index :token_digest, unique: true
      index [:project_id, :email]
    end
  end
end
