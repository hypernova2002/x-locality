# frozen_string_literal: true

Sequel.migration do
  up do
    run "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    run "CREATE INDEX translations_key_trgm_idx ON translations USING gin (key gin_trgm_ops)"
    run "CREATE INDEX translations_translated_text_trgm_idx ON translations USING gin (translated_text gin_trgm_ops)"
  end

  down do
    run "DROP INDEX IF EXISTS translations_translated_text_trgm_idx"
    run "DROP INDEX IF EXISTS translations_key_trgm_idx"
    run "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
