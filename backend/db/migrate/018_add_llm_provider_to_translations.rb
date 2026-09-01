# frozen_string_literal: true

# Captures which provider generated a translation at the time it was
# generated (mirrors model_used) - a project's llm_provider can change over
# time, so this can't be reliably derived after the fact from the project.
Sequel.migration do
  up do
    alter_table(:translations) do
      add_column :llm_provider, String
    end

    run "CREATE INDEX translations_source_text_trgm_idx ON translations USING gin (source_text gin_trgm_ops)"
  end

  down do
    run "DROP INDEX IF EXISTS translations_source_text_trgm_idx"

    alter_table(:translations) do
      drop_column :llm_provider
    end
  end
end
