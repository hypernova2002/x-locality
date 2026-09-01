# frozen_string_literal: true

# Whitelabel branding: a logo (URL - no upload infra exists yet, so the
# account links to an image they host) and a dedicated "From" display name
# for outgoing emails, distinct from the in-app account name.
Sequel.migration do
  change do
    alter_table(:accounts) do
      add_column :logo_url, String
      add_column :correspondence_name, String
    end
  end
end
