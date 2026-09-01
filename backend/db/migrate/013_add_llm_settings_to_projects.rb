# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:projects) do
      add_column :llm_provider, String, null: false, default: "anthropic"
      add_column :llm_api_key_ciphertext, String, text: true
    end
  end
end
