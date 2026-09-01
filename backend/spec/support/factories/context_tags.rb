# frozen_string_literal: true

FactoryBot.define do
  factory :context_tag, class: "Backend::Models::ContextTag" do
    association :project
    sequence(:key) { |n| "tag-#{n}" }
    description { "A test context tag" }
  end
end
