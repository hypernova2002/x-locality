# frozen_string_literal: true

module Backend
  module Serializers
    class UserSerializer
      include Alba::Resource

      attributes :email, :role, :created_at

      attribute :id, &:public_id
    end
  end
end
