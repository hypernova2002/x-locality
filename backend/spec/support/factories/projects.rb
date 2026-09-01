# frozen_string_literal: true

FactoryBot.define do
  factory :project, class: "Backend::Models::Project" do
    association :account
    sequence(:name) { |n| "Project #{n}" }
    sequence(:slug) { |n| "project-#{n}" }

    # project.llm_config caches its (nil) result the first time it's
    # called, so both this and the trait callback below query the table
    # directly rather than risk two callbacks both seeing a stale nil and
    # both trying to create the row.
    after(:create) do |project|
      unless Backend::Models::LlmConfig.first(project_id: project.id)
        Backend::Models::LlmConfig.create(project_id: project.id)
      end
    end

    trait :with_llm_configured do
      after(:create) do |project|
        llm_config = Backend::Models::LlmConfig.first(project_id: project.id) ||
          Backend::Models::LlmConfig.create(project_id: project.id)

        provider_config = Backend::Models::LlmProviderConfig.create(
          project_id: project.id, name: "Default", provider: "anthropic"
        )
        provider_config.api_key = "test-llm-api-key"
        provider_config.save

        llm_config.update(active_llm_provider_config_id: provider_config.id)
      end
    end
  end
end
