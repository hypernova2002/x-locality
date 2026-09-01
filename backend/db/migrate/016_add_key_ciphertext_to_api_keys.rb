# frozen_string_literal: true

# API keys can now be viewed after creation (not just shown once), so the
# plaintext needs to be recoverable - encrypted at rest, same as
# projects.llm_api_key_ciphertext. key_digest (SHA256) is unchanged and
# still does the actual auth lookup.
Sequel.migration do
  change do
    alter_table(:api_keys) do
      add_column :key_ciphertext, String, text: true
    end
  end
end
