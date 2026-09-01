# frozen_string_literal: true

module Backend
  module Serializers
    class AccountSerializer
      include Alba::Resource

      attributes :name, :timezone, :logo_url, :correspondence_name, :created_at

      attribute :id do |account|
        account.public_id
      end
    end
  end
end
