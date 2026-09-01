# frozen_string_literal: true

# Failed LLM calls are now logged too (with zeroed token counts, since no
# response was received), so the usage views can show call success/failure
# counts alongside token/cost totals. Existing rows predate this and were
# all successful, hence the default.
Sequel.migration do
  change do
    alter_table(:llm_usage_events) do
      add_column :success, TrueClass, default: true, null: false
    end
  end
end
