# frozen_string_literal: true

# The account's display timezone - the API itself always stores/returns UTC
# (see config/providers/db.rb); this is purely how the frontend renders
# those UTC timestamps back to users.
Sequel.migration do
  change do
    alter_table(:accounts) do
      add_column :timezone, String, null: false, default: "UTC"
    end
  end
end
