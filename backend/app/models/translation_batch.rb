# frozen_string_literal: true

module Backend
  module Models
    class TranslationBatch < Sequel::Model
      include Concerns::HasPublicId
      public_id_prefix "tslbatch"

      many_to_one :project
      one_to_many :items, class: TranslationBatchItem, key: :translation_batch_id
    end
  end
end
