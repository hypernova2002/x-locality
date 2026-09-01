# frozen_string_literal: true

# Mandated term translations, automatically injected into the LLM prompt
# when a matching source_term appears in an item's source_text (same
# source_language only - see Backend::Translations::Create). Distinct from
# ContextTags, which are a per-translation opt-in hint rather than an
# automatic, mandatory mapping.
Sequel.migration do
  change do
    create_table(:glossary_terms) do
      primary_key :id
      column :public_id, String, null: false, unique: true
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
      # null means the mapping applies regardless of target locale - e.g. a
      # brand name that should never be translated.
      foreign_key :target_locale_id, :locales, null: true, on_delete: :cascade

      column :source_term, String, null: false
      column :source_language, String, null: false
      column :target_term, String, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:project_id, :source_language]
      index [:project_id, :source_term, :source_language, :target_locale_id], unique: true,
        name: :glossary_terms_uniqueness
    end
  end
end
