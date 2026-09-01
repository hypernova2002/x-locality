# frozen_string_literal: true

module Backend
  module Models
    class Account < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'acct'

      one_to_many :users
      one_to_many :projects
      one_to_many :invites

      def owner
        users_dataset.first(role: 'owner')
      end
    end
  end
end
