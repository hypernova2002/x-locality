# frozen_string_literal: true

module Backend
  module Serializers
    # Never includes the actual api_key - only whether one is configured.
    class LlmProviderConfigSerializer
      include Alba::Resource

      attributes :name, :description, :provider, :created_at, :updated_at

      attribute :id, &:public_id

      attribute :model, &:llm_model

      attribute :api_key_configured, &:api_key_configured?
    end
  end
end
