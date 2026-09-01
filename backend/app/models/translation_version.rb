# frozen_string_literal: true

module Backend
  module Models
    class TranslationVersion < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'tslver'

      many_to_one :translation
      many_to_one :changed_by_user, class: User, key: :changed_by_user_id
    end
  end
end
