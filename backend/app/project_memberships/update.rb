# frozen_string_literal: true

module Backend
  module ProjectMemberships
    class Update < Backend::Operation
      ROLES = %w[admin member].freeze

      def call(membership:, role:)
        step check_role(role)

        membership.update(role: role)
        membership
      end

      private

      def check_role(role)
        return Failure([:validation, "role must be one of: #{ROLES.join(", ")}"]) unless ROLES.include?(role)

        Success(true)
      end
    end
  end
end
