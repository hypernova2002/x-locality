# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:translations) do
      add_column :locked, TrueClass, default: false, null: false
    end
  end
end
