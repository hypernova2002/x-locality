# frozen_string_literal: true

module Backend
  module Llm
    Usage = Struct.new(:input_tokens, :output_tokens, keyword_init: true)
  end
end
