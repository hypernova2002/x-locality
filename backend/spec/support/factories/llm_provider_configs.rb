# frozen_string_literal: true

FactoryBot.define do
  factory :llm_provider_config, class: 'Backend::Models::LlmProviderConfig' do
    association :project
    sequence(:name) { |n| "LLM Config #{n}" }
    provider { 'anthropic' }
    llm_model { 'claude-opus-5' }

    after(:create) do |config|
      config.api_key = 'test-llm-api-key'
      config.save
    end
  end
end
