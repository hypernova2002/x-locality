# frozen_string_literal: true

module Backend
  module ContextTags
    class Create < Backend::Operation
      def call(project:, key:, description: nil)
        step check_key_available(project, key)

        Backend::Models::ContextTag.create(
          project_id: project.id,
          key: key,
          description: description
        )
      end

      private

      def check_key_available(project, key)
        if project.context_tags_dataset.first(key: key)
          return Failure([:conflict, 'A context tag with this key already exists on this project'])
        end

        Success(true)
      end
    end
  end
end
