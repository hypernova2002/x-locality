# frozen_string_literal: true

module Backend
  module Models
    class Translation < Sequel::Model
      include Concerns::HasPublicId
      public_id_prefix "tsl"

      many_to_one :project
      many_to_one :locale
      many_to_many :context_tags,
        join_table: :translation_context_tags,
        left_key: :translation_id,
        right_key: :context_tag_id
      one_to_many :versions, class: TranslationVersion, key: :translation_id

      def record_version!(previous_value:, new_value:, changed_by_type:, changed_by_user: nil)
        TranslationVersion.create(
          translation: self,
          previous_value: previous_value,
          new_value: new_value,
          changed_by_type: changed_by_type,
          changed_by_user: changed_by_user
        )
      end
    end
  end
end
