# frozen_string_literal: true

require 'securerandom'

module Backend
  module PublicId
    module_function

    def generate(prefix, length: 12)
      "#{prefix}_#{SecureRandom.alphanumeric(length)}"
    end
  end
end
