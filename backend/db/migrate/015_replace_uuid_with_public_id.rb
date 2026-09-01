# frozen_string_literal: true

require "securerandom"

# UUIDs (36 chars) were overkill for public-facing ids - replaced with a
# short, prefixed, random id (e.g. "proj_a1b2c3d4e5f6") in the same spirit:
# opaque and decoupled from the internal bigint `id`, just shorter. Prefixes
# make ids self-describing in logs and catch cross-resource-type mixups.
Sequel.migration do
  TABLE_PREFIXES = {
    accounts: "acct",
    users: "user",
    projects: "proj",
    api_keys: "apikey",
    locales: "loc",
    context_tags: "ctag",
    translations: "tsl",
    translation_versions: "tslver",
    translation_batches: "tslbatch",
    translation_batch_items: "tslitem"
  }.freeze

  up do
    TABLE_PREFIXES.each do |table, prefix|
      alter_table(table) do
        drop_index :uuid
        drop_column :uuid
        add_column :public_id, String
      end

      from(table).select(:id).each do |row|
        from(table).where(id: row[:id]).update(public_id: "#{prefix}_#{SecureRandom.alphanumeric(12)}")
      end

      alter_table(table) do
        set_column_not_null :public_id
        add_index :public_id, unique: true
      end
    end
  end

  down do
    TABLE_PREFIXES.each_key do |table|
      alter_table(table) do
        drop_index :public_id
        drop_column :public_id
        add_column :uuid, :uuid, null: false, default: Sequel.lit("gen_random_uuid()")
        add_index :uuid, unique: true
      end
    end
  end
end
