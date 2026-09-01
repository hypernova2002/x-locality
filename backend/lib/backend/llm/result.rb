# frozen_string_literal: true

module Backend
  module Llm
    # `usage` covers the whole API call this result came from (a single call
    # can translate several items at once) - every Result from the same
    # #translate call carries the same Usage.
    Result = Struct.new(:key, :translated_text, :detected_source_language, :usage, keyword_init: true)
  end
end
