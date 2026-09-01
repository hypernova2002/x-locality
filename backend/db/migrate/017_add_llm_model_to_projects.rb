# frozen_string_literal: true

# Free text, not an enum - model names/tiers change often across providers,
# and the project just passes it straight through to whichever adapter it's
# configured for. No value means "use the adapter's own default".
Sequel.migration do
  change do
    alter_table(:projects) do
      add_column :llm_model, String
    end
  end
end
