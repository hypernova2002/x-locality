# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: 'Backend::Models::User' do
    association :account
    sequence(:email) { |n| "user#{n}@example.test" }
    password { 'supersecret123' }
    role { 'owner' }
  end
end
