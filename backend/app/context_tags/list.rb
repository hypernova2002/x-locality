# frozen_string_literal: true

module Backend
  module ContextTags
    class List < Backend::Operation
      def call(project:, search: nil)
        dataset = project.context_tags_dataset.order(:key)
        return dataset if search.nil? || search.empty?

        dataset.where(Sequel.ilike(:key, "%#{search}%") | Sequel.ilike(:description, "%#{search}%"))
      end
    end
  end
end
