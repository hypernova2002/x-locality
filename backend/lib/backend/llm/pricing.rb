# frozen_string_literal: true

module Backend
  module Llm
    # Best-effort $/token pricing, manually maintained - there's no live
    # pricing feed. Rates are USD per single token (list prices, not
    # accounting for prompt caching/batch discounts). Keyed by exact model
    # id; an unlisted model (custom/future) simply has no cost calculated,
    # only token counts.
    module Pricing
      RATES = {
        'claude-opus-5' => { input: 15.0 / 1_000_000, output: 75.0 / 1_000_000 },
        'claude-sonnet-5' => { input: 3.0 / 1_000_000, output: 15.0 / 1_000_000 },
        'claude-haiku-4-5' => { input: 1.0 / 1_000_000, output: 5.0 / 1_000_000 },
        'gemini-3.5-flash' => { input: 0.075 / 1_000_000, output: 0.30 / 1_000_000 },
        'gemini-3.5-pro' => { input: 1.25 / 1_000_000, output: 5.0 / 1_000_000 },
        'gpt-5.2' => { input: 0.88 / 1_000_000, output: 7.0 / 1_000_000 },
        # Per character, not per token - TranslateAdapter reports character
        # count as input_tokens (output_tokens always 0), so this rate is
        # applied the same way as everything else above despite the unit.
        'amazon-translate' => { input: 15.0 / 1_000_000, output: 0 }
        # Bedrock models aren't priced here - the catalog is large, varies
        # by region, and there's no single default model to anchor on the
        # way there is for the other providers. Falls back to "no cost
        # calculated, only token counts" like any other unlisted model.
      }.freeze

      def self.cost(model:, input_tokens:, output_tokens:)
        rate = RATES[model]
        return nil unless rate

        (input_tokens * rate[:input]) + (output_tokens * rate[:output])
      end
    end
  end
end
