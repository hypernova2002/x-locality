# frozen_string_literal: true

FactoryBot.define do
  factory :api_key, class: "Backend::Models::APIKey" do
    transient do
      plaintext_key { "xloc_test_#{SecureRandom.hex(8)}" }
    end

    association :project
    sequence(:name) { |n| "API Key #{n}" }
    key_digest { Backend::Models::APIKey.digest(plaintext_key) }
  end
end
