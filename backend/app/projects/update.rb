# frozen_string_literal: true

module Backend
  module Projects
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent (partial
      # update) - callers should filter with `Hash#slice`/presence checks
      # before calling, not pass every possible key unconditionally.
      def call(project:, updates:)
        project.name = updates[:name] if updates.key?(:name)
        project.save

        project
      end
    end
  end
end
