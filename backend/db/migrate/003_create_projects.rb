# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:projects) do
      primary_key :id
      foreign_key :account_id, :accounts, null: false, on_delete: :cascade

      column :name, String, null: false
      column :slug, String, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:account_id, :slug], unique: true
    end
  end
end
