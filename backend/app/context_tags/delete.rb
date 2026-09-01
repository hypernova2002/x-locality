# frozen_string_literal: true

module Backend
  module ContextTags
    class Delete < Backend::Operation
      def call(context_tag:)
        context_tag.destroy
        context_tag
      end
    end
  end
end
