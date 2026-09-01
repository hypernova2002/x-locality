# frozen_string_literal: true

# A real Ruby class standing in for an LLM adapter (Backend::Llm::*Adapter) -
# "translates" by looking up canned results per key, no real network call
# ever. Deliberately not an RSpec double: a plain class + Result.new() called
# from an ordinary method has normal, predictable Ruby semantics, unlike a
# value built inside a `receive(:foo) do ... end` block, which trips a
# reproducible autoload-ordering quirk once actually invoked.
class FakeLlmAdapter
  attr_reader :model, :call_count
  attr_writer :usage, :raises

  def initialize(results_by_key:)
    @results_by_key = results_by_key
    @usage = Backend::Llm::Usage.new(input_tokens: 100, output_tokens: 20)
    @model = 'claude-opus-5'
    @raises = nil
    @call_count = 0
  end

  def translate(items:, locale:) # rubocop:disable Lint/UnusedMethodArgument
    @call_count += 1
    raise @raises if @raises

    items.map do |item|
      Backend::Llm::Result.new(
        key: item[:key], translated_text: @results_by_key.fetch(item[:key]),
        detected_source_language: 'en', usage: @usage
      )
    end
  end
end
