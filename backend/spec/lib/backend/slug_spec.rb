# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Slug do
  describe ".generate" do
    it "downcases and hyphenates" do
      expect(described_class.generate("Marketing Site")).to eq("marketing-site")
    end

    it "strips non-alphanumeric characters" do
      expect(described_class.generate("Acme, Inc.! 2026")).to eq("acme-inc-2026")
    end

    it "trims leading and trailing hyphens" do
      expect(described_class.generate("  --Weird Name--  ")).to eq("weird-name")
    end

    it "collapses runs of separators into one hyphen" do
      expect(described_class.generate("a   b---c")).to eq("a-b-c")
    end
  end
end
