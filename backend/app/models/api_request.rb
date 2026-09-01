# frozen_string_literal: true

module Backend
  module Models
    class APIRequest < Sequel::Model
      many_to_one :project
      many_to_one :api_key
    end
  end
end
