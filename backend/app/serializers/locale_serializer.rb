# frozen_string_literal: true

module Backend
  module Serializers
    class LocaleSerializer
      include Alba::Resource

      attributes :key, :target_language, :style_tone_text, :general_description,
                 :system, :created_at, :updated_at

      attribute :id, &:public_id
    end
  end
end
