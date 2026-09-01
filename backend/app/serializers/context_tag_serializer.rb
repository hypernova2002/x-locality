# frozen_string_literal: true

module Backend
  module Serializers
    class ContextTagSerializer
      include Alba::Resource

      attributes :key, :description, :created_at, :updated_at

      attribute :id do |context_tag|
        context_tag.public_id
      end
    end
  end
end
