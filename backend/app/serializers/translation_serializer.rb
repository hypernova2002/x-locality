# frozen_string_literal: true

module Backend
  module Serializers
    class TranslationSerializer
      include Alba::Resource

      attributes :key, :source_text, :source_language, :detected_language,
                 :translated_text, :status, :generated_by, :llm_provider, :model_used, :created_at, :updated_at

      attribute :id, &:public_id

      attribute :locale do |translation|
        translation.locale.key
      end

      attribute :context_tags do |translation|
        translation.context_tags.map(&:key)
      end
    end
  end
end
