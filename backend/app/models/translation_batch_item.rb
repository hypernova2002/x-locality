# frozen_string_literal: true

module Backend
  module Models
    class TranslationBatchItem < Sequel::Model
      include Concerns::HasPublicId
      public_id_prefix "tslitem"

      many_to_one :translation_batch
      many_to_one :locale
    end
  end
end
