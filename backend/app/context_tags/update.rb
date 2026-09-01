# frozen_string_literal: true

module Backend
  module ContextTags
    class Update < Backend::Operation
      # `updates` only contains keys the client actually sent.
      def call(context_tag:, updates:)
        step check_key_available(context_tag, updates[:key]) if updates[:key] && updates[:key] != context_tag.key

        context_tag.update(updates.slice(:key, :description))
        context_tag
      end

      private

      def check_key_available(context_tag, key)
        if context_tag.project.context_tags_dataset.first(key: key)
          return Failure([:conflict, 'A context tag with this key already exists on this project'])
        end

        Success(true)
      end
    end
  end
end
