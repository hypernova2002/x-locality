# frozen_string_literal: true

# Moves LLM provider/model/api_key off Project into its own 1:1 table, and
# adds configurable monthly cost/token budgets - a home purpose-built for
# "which model is this project currently using" and "how much can it
# spend", rather than mixed into the project's own basic fields.
Sequel.migration do
  up do
    create_table(:llm_configs) do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade, unique: true

      column :provider, String, null: false, default: "anthropic"
      column :model, String
      column :api_key_ciphertext, String, text: true
      column :monthly_cost_limit_usd, :numeric, size: [10, 2]
      column :monthly_token_limit, Integer

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    run <<~SQL
      INSERT INTO llm_configs (project_id, provider, model, api_key_ciphertext, created_at, updated_at)
      SELECT id, llm_provider, llm_model, llm_api_key_ciphertext, now(), now() FROM projects
    SQL

    alter_table(:projects) do
      drop_column :llm_provider
      drop_column :llm_model
      drop_column :llm_api_key_ciphertext
    end
  end

  down do
    alter_table(:projects) do
      add_column :llm_provider, String, null: false, default: "anthropic"
      add_column :llm_model, String
      add_column :llm_api_key_ciphertext, String, text: true
    end

    run <<~SQL
      UPDATE projects SET
        llm_provider = llm_configs.provider,
        llm_model = llm_configs.model,
        llm_api_key_ciphertext = llm_configs.api_key_ciphertext
      FROM llm_configs WHERE llm_configs.project_id = projects.id
    SQL

    drop_table(:llm_configs)
  end
end
