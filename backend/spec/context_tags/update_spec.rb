# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::ContextTags::Update do
  let(:project) { create(:project) }

  describe "#call" do
    it "updates the description" do
      tag = create(:context_tag, project: project, key: "fruit", description: "old")

      result = described_class.new.call(context_tag: tag, updates: { description: "new" })

      expect(result.value!.description).to eq("new")
    end

    it "updates the key when available" do
      tag = create(:context_tag, project: project, key: "fruit")

      result = described_class.new.call(context_tag: tag, updates: { key: "produce" })

      expect(result.value!.key).to eq("produce")
    end

    it "fails with :conflict when renaming to a key already used on the project" do
      create(:context_tag, project: project, key: "brand")
      tag = create(:context_tag, project: project, key: "fruit")

      result = described_class.new.call(context_tag: tag, updates: { key: "brand" })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:conflict)
      expect(tag.reload.key).to eq("fruit")
    end

    it "allows renaming to its own current key without conflict" do
      tag = create(:context_tag, project: project, key: "fruit")

      result = described_class.new.call(context_tag: tag, updates: { key: "fruit", description: "updated" })

      expect(result).to be_success
    end
  end
end
