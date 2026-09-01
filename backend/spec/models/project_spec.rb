# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Models::Project do
  describe 'associations' do
    it 'has many api_keys (mapped through the API acronym class name)' do
      project = create(:project)
      api_key = create(:api_key, project: project)

      expect(project.api_keys.map(&:id)).to contain_exactly(api_key.id)
    end

    it 'has one llm_config' do
      project = create(:project)

      expect(project.llm_config).to be_a(Backend::Models::LlmConfig)
      expect(project.llm_config.project_id).to eq(project.id)
    end

    it 'has many llm_provider_configs' do
      project = create(:project)
      config = create(:llm_provider_config, project: project)

      expect(project.llm_provider_configs.map(&:id)).to contain_exactly(config.id)
    end
  end

  describe '#effective_role_for' do
    it 'is admin for the account owner, with no explicit membership row' do
      account = create(:account)
      owner = create(:user, account: account, role: 'owner')
      project = create(:project, account: account)

      expect(project.effective_role_for(owner)).to eq('admin')
      expect(project.project_memberships_dataset.count).to eq(0)
    end

    it 'matches the explicit membership role for a non-owner' do
      account = create(:account)
      member = create(:user, account: account, role: 'member')
      project = create(:project, account: account)
      create(:project_membership, project: project, user: member, role: 'admin')

      expect(project.effective_role_for(member)).to eq('admin')
    end

    it "is nil when the user has no membership and isn't the owner" do
      account = create(:account)
      member = create(:user, account: account, role: 'member')
      project = create(:project, account: account)

      expect(project.effective_role_for(member)).to be_nil
    end

    it 'is nil for a user from a different account, even if they happen to be an owner' do
      project = create(:project)
      other_owner = create(:user, role: 'owner')

      expect(project.effective_role_for(other_owner)).to be_nil
    end
  end
end
