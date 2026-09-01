# frozen_string_literal: true

module Backend
  module Models
    class ContextTag < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'ctag'

      many_to_one :project
      many_to_many :translations,
                   join_table: :translation_context_tags,
                   left_key: :context_tag_id,
                   right_key: :translation_id
    end
  end
end
