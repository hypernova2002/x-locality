# frozen_string_literal: true

# AWS-backed providers (Bedrock, Amazon Translate) authenticate with an
# access key id + secret access key + region, not a single API key.
# api_key_ciphertext is reused for the access key id; this adds the secret
# and region alongside it.
Sequel.migration do
  change do
    alter_table(:llm_provider_configs) do
      add_column :api_secret_ciphertext, String, text: true
      add_column :region, String
    end
  end
end
