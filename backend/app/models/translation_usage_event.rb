# frozen_string_literal: true

module Backend
  module Models
    class TranslationUsageEvent < Sequel::Model
      many_to_one :project
      many_to_one :locale
    end
  end
end
