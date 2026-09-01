# frozen_string_literal: true

module Backend
  module Serializers
    class TranslationVersionSerializer
      include Alba::Resource

      attributes :previous_value, :new_value, :changed_by_type, :created_at

      attribute :id do |version|
        version.public_id
      end

      attribute :changed_by_user_email do |version|
        version.changed_by_user&.email
      end
    end
  end
end
