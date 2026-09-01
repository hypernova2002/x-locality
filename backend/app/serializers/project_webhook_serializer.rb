# frozen_string_literal: true

module Backend
  module Serializers
    class ProjectWebhookSerializer
      include Alba::Resource

      attributes :url, :secret, :event_types, :enabled, :created_at, :updated_at

      attribute :id, &:public_id
    end
  end
end
