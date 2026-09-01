# frozen_string_literal: true

module Backend
  module Slug
    module_function

    def generate(text)
      text.to_s.downcase.strip.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end
  end
end
