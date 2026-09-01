# frozen_string_literal: true

module Backend
  module Models
    class ProjectWebhook < Sequel::Model
      include Concerns::HasPublicId
      public_id_prefix "whk"

      EVENT_TYPES = %w[translation.batch_completed budget.threshold_crossed].freeze

      many_to_one :project
      one_to_many :webhook_deliveries, order: Sequel.desc(:created_at)

      def subscribed_to?(event_type)
        enabled && event_types.include?(event_type)
      end
    end
  end
end
