# frozen_string_literal: true

module Backend
  module Models
    class GlossaryTerm < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'glos'

      many_to_one :project
      many_to_one :target_locale, class: 'Backend::Models::Locale'
    end
  end
end
