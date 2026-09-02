# frozen_string_literal: true

FactoryBot.define do
  factory :glossary_term, class: 'Backend::Models::GlossaryTerm' do
    association :project
    sequence(:source_term) { |n| "term-#{n}" }
    source_language { 'en' }
    target_term { 'terme' }
  end
end
