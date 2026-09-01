# frozen_string_literal: true

module Backend
  module Models
    class ProjectMembership < Sequel::Model
      many_to_one :project
      many_to_one :user

      def admin?
        role == "admin"
      end
    end
  end
end
