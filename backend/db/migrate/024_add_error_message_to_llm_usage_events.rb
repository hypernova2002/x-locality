# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:llm_usage_events) do
      add_column :error_message, String, text: true
    end
  end
end
