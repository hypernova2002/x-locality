# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::ContextTags::Delete do
  describe '#call' do
    it 'deletes the context tag' do
      tag = create(:context_tag)

      result = described_class.new.call(context_tag: tag)

      expect(result).to be_success
      expect(Backend::Models::ContextTag[tag.id]).to be_nil
    end
  end
end
