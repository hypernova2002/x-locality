# frozen_string_literal: true

module Backend
  module Models
    class WebhookDelivery < Sequel::Model
      many_to_one :project_webhook
    end
  end
end
