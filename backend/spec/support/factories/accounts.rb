# frozen_string_literal: true

FactoryBot.define do
  factory :account, class: "Backend::Models::Account" do
    sequence(:name) { |n| "Account #{n}" }
  end
end
