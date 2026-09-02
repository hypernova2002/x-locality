# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::ContextTags::List do
  let(:project) { create(:project) }

  describe '#call' do
    it 'returns every context tag for the project, ordered by key' do
      create(:context_tag, project: project, key: 'fruit')
      create(:context_tag, project: project, key: 'brand')

      records = described_class.new.call(project: project).value!.all

      expect(records.map(&:key)).to eq(%w[brand fruit])
    end

    it "does not return another project's context tags" do
      create(:context_tag, project: project, key: 'mine')
      other_project = create(:project)
      create(:context_tag, project: other_project, key: 'theirs')

      records = described_class.new.call(project: project).value!.all

      expect(records.map(&:key)).to eq(['mine'])
    end

    it 'matches on key' do
      create(:context_tag, project: project, key: 'fruit', description: 'A type of food')
      create(:context_tag, project: project, key: 'brand', description: 'A company name')

      records = described_class.new.call(project: project, search: 'FRUI').value!.all

      expect(records.map(&:key)).to eq(['fruit'])
    end

    it 'matches on description' do
      create(:context_tag, project: project, key: 'fruit', description: 'A type of food')
      create(:context_tag, project: project, key: 'brand', description: 'A company name')

      records = described_class.new.call(project: project, search: 'company').value!.all

      expect(records.map(&:key)).to eq(['brand'])
    end

    it 'ignores a nil description when matching' do
      create(:context_tag, project: project, key: 'fruit', description: nil)

      records = described_class.new.call(project: project, search: 'fruit').value!.all

      expect(records.map(&:key)).to eq(['fruit'])
    end
  end
end
