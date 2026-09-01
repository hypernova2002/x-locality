# frozen_string_literal: true

FactoryBot.define do
  factory :translation, class: "Backend::Models::Translation" do
    association :project
    association :locale
    sequence(:key) { |n| "translation-key-#{n}" }
    source_text { "Hello world" }
    status { "pending" }
    generated_by { "llm" }
  end
end
