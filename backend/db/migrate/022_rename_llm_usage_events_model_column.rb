# frozen_string_literal: true

# Sequel::Model instances already define #model (returns the model class) -
# a plain `model` column silently shadows it instead of raising, so the
# column needs a name that doesn't collide.
Sequel.migration do
  change do
    alter_table(:llm_usage_events) do
      rename_column :model, :llm_model
    end
  end
end
