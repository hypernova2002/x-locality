# frozen_string_literal: true

# Splits "which LLM provider/model/key" out of the project's single
# llm_config row into a named, reusable list (llm_provider_configs) - so a
# project can save several (e.g. different models or keys) and switch its
# active one without re-entering credentials. Duplicates (same
# provider/model, different key) are intentionally allowed, so there is no
# uniqueness constraint here beyond the primary key.
Sequel.migration do
  up do
    create_table(:llm_provider_configs) do
      primary_key :id
      column :public_id, String, null: false, unique: true
      foreign_key :project_id, :projects, null: false, on_delete: :cascade

      column :name, String, null: false
      column :description, String, text: true
      column :provider, String, null: false, default: "anthropic"
      column :llm_model, String
      column :api_key_ciphertext, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index :project_id
    end

    alter_table(:llm_configs) do
      add_foreign_key :active_llm_provider_config_id, :llm_provider_configs, null: true, on_delete: :set_null
    end

    run <<~SQL
      INSERT INTO llm_provider_configs (public_id, project_id, name, provider, llm_model, api_key_ciphertext, created_at, updated_at)
      SELECT 'llmpc_' || substr(md5(random()::text || project_id::text || clock_timestamp()::text), 1, 20),
             project_id, 'Default', provider, llm_model, api_key_ciphertext, now(), now()
      FROM llm_configs
    SQL

    run <<~SQL
      UPDATE llm_configs
      SET active_llm_provider_config_id = llm_provider_configs.id
      FROM llm_provider_configs
      WHERE llm_provider_configs.project_id = llm_configs.project_id
    SQL

    alter_table(:llm_configs) do
      drop_column :provider
      drop_column :llm_model
      drop_column :api_key_ciphertext
    end
  end

  down do
    alter_table(:llm_configs) do
      add_column :provider, String, null: false, default: "anthropic"
      add_column :llm_model, String
      add_column :api_key_ciphertext, String, text: true
    end

    run <<~SQL
      UPDATE llm_configs
      SET provider = llm_provider_configs.provider,
          llm_model = llm_provider_configs.llm_model,
          api_key_ciphertext = llm_provider_configs.api_key_ciphertext
      FROM llm_provider_configs
      WHERE llm_provider_configs.id = llm_configs.active_llm_provider_config_id
    SQL

    alter_table(:llm_configs) do
      drop_column :active_llm_provider_config_id
    end

    drop_table(:llm_provider_configs)
  end
end
