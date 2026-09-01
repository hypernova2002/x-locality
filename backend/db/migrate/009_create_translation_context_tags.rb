# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:translation_context_tags) do
      foreign_key :translation_id, :translations, null: false, on_delete: :cascade
      foreign_key :context_tag_id, :context_tags, null: false, on_delete: :cascade

      primary_key [:translation_id, :context_tag_id]
    end
  end
end
