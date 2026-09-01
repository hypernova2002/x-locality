# frozen_string_literal: true

module Backend
  module Serializers
    class WebhookDeliverySerializer
      include Alba::Resource

      attributes :event_type, :response_status, :error_message, :success, :created_at

      attribute :id, &:id
    end
  end
end
