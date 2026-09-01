# frozen_string_literal: true

module Backend
  module Models
    class LlmUsageEvent < Sequel::Model
      many_to_one :project
      many_to_one :locale
    end
  end
end
