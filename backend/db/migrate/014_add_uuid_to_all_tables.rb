# frozen_string_literal: true

# Internal FKs/joins keep using the bigint `id` primary key (cheaper to
# index and join on). `uuid` is the only identifier ever exposed to API
# clients - decouples external references from internal row numbering.
Sequel.migration do
  TABLES = %i[
    accounts users projects api_keys locales context_tags
    translations translation_versions translation_batches translation_batch_items
  ].freeze

  up do
    TABLES.each do |table|
      alter_table(table) do
        add_column :uuid, :uuid, null: false, default: Sequel.lit("gen_random_uuid()")
        add_index :uuid, unique: true
      end
    end
  end

  down do
    TABLES.each do |table|
      alter_table(table) do
        drop_column :uuid
      end
    end
  end
end
