# frozen_string_literal: true

FactoryBot.define do
  factory :project_membership, class: "Backend::Models::ProjectMembership" do
    association :project
    association :user
    role { "member" }
  end
end
