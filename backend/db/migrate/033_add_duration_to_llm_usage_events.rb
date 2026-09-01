# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:llm_usage_events) do
      add_column :duration_ms, Integer
    end
  end
end
