# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::ContextTags::Create do
  let(:project) { create(:project) }

  describe '#call' do
    it 'creates a context tag on the project' do
      result = described_class.new.call(project: project, key: 'fruit', description: 'Fruit-related context')

      tag = result.value!
      expect(tag.key).to eq('fruit')
      expect(tag.description).to eq('Fruit-related context')
      expect(tag.project_id).to eq(project.id)
    end

    it 'allows a nil description' do
      result = described_class.new.call(project: project, key: 'brand')

      expect(result.value!.description).to be_nil
    end

    it 'fails with :conflict when the key already exists on the project' do
      create(:context_tag, project: project, key: 'fruit')

      result = described_class.new.call(project: project, key: 'fruit')

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
    end

    it 'allows the same key on a different project' do
      other_project = create(:project)
      create(:context_tag, project: other_project, key: 'fruit')

      result = described_class.new.call(project: project, key: 'fruit')

      expect(result).to be_success
    end
  end
end
