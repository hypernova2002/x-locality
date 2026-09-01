# frozen_string_literal: true

# Optional per-project Langfuse tracing - a public/secret key pair (Basic
# Auth against the self-hosted Langfuse instance's OTLP endpoint) plus a
# toggle, alongside the rest of the project's LLM settings.
Sequel.migration do
  change do
    alter_table(:llm_configs) do
      add_column :langfuse_enabled, TrueClass, null: false, default: false
      add_column :langfuse_public_key, String
      add_column :langfuse_secret_key_ciphertext, String, text: true
    end
  end
end
