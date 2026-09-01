# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Projects::Update do
  describe '#call' do
    it 'updates the name' do
      project = create(:project, name: 'Old Name')

      result = described_class.new.call(project: project, updates: { name: 'New Name' })

      expect(result.value!.name).to eq('New Name')
    end

    it 'leaves the name untouched when absent from updates' do
      project = create(:project, name: 'Original')

      described_class.new.call(project: project, updates: {})

      expect(project.reload.name).to eq('Original')
    end
  end
end
