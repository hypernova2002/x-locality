# frozen_string_literal: true

module Backend
  module ProjectMemberships
    class Delete < Backend::Operation
      def call(membership:)
        membership.destroy
        membership
      end
    end
  end
end
