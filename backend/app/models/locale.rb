# frozen_string_literal: true

module Backend
  module Models
    class Locale < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'loc'

      many_to_one :project
      one_to_many :translations
    end
  end
end
