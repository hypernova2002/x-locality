# frozen_string_literal: true

module Backend
  module Serializers
    class UserSerializer
      include Alba::Resource

      attributes :email, :role, :created_at

      attribute :id do |user|
        user.public_id
      end
    end
  end
end
