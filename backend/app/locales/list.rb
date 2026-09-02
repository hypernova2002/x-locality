# frozen_string_literal: true

module Backend
  module Locales
    # Filtering only - pagination stays in the action via the shared
    # `paginate` helper, unchanged from before this existed.
    class List < Backend::Operation
      def call(project:, key_filter: nil, language_filter: nil, system_filter: nil)
        dataset = project.locales_dataset.order(:key)
        dataset = dataset.where(Sequel.ilike(:key, "%#{key_filter}%")) if key_filter && !key_filter.empty?
        dataset = dataset.where(target_language: language_filter) if language_filter && !language_filter.empty?
        dataset = dataset.where(system: system_filter == 'true') if %w[true false].include?(system_filter)
        dataset
      end
    end
  end
end
