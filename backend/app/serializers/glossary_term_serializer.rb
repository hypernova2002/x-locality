# frozen_string_literal: true

module Backend
  module Serializers
    class GlossaryTermSerializer
      include Alba::Resource

      attributes :source_term, :source_language, :target_term, :created_at, :updated_at

      attribute :id do |term|
        term.public_id
      end

      # null means the mapping applies regardless of target locale.
      attribute :target_locale do |term|
        term.target_locale&.key
      end
    end
  end
end
