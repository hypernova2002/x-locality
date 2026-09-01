# frozen_string_literal: true

FactoryBot.define do
  factory :locale, class: 'Backend::Models::Locale' do
    association :project
    sequence(:key) { |n| "loc-#{n}" }
    target_language { 'fr' }
    system { false }
  end
end
