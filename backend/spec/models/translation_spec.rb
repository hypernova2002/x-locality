# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Models::Translation do
  describe 'context_tags association' do
    # Sequel's many_to_many has no bulk `=` setter - this is exactly the
    # assumption that broke Translations::Create in production. Pin the
    # correct add/remove_all pattern here so a regression fails loudly.
    it 'has no bulk setter method' do
      translation = create(:translation)

      expect(translation).not_to respond_to(:context_tags=)
    end

    it 'can have tags added and cleared via add_context_tag / remove_all_context_tags' do
      translation = create(:translation)
      tag_a = create(:context_tag, project: translation.project)
      tag_b = create(:context_tag, project: translation.project)

      translation.add_context_tag(tag_a)
      translation.add_context_tag(tag_b)
      expect(translation.reload.context_tags.map(&:id)).to contain_exactly(tag_a.id, tag_b.id)

      translation.remove_all_context_tags
      expect(translation.reload.context_tags).to be_empty
    end
  end

  describe '#record_version!' do
    it 'creates a translation_version row' do
      translation = create(:translation)

      expect do
        translation.record_version!(
          previous_value: nil, new_value: 'Bonjour', changed_by_type: 'llm'
        )
      end.to change { translation.versions_dataset.count }.by(1)
    end

    it 'records the previous and new values' do
      translation = create(:translation)

      version = translation.record_version!(
        previous_value: 'old', new_value: 'new', changed_by_type: 'user'
      )

      expect(version.previous_value).to eq('old')
      expect(version.new_value).to eq('new')
      expect(version.changed_by_type).to eq('user')
    end
  end

  describe 'public_id' do
    it 'uses the tsl prefix' do
      expect(create(:translation).public_id).to start_with('tsl_')
    end
  end
end
