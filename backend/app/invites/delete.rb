# frozen_string_literal: true

module Backend
  module Invites
    class Delete < Backend::Operation
      def call(invite:)
        invite.destroy
        invite
      end
    end
  end
end
