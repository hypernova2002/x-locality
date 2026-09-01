# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Jwt do
  let(:secret) { "test-secret" }

  describe ".encode / .decode" do
    it "round-trips a payload" do
      token = described_class.encode({ user_id: 42 }, secret: secret, ttl: 3600)
      decoded = described_class.decode(token, secret: secret)

      expect(decoded["user_id"]).to eq(42)
    end

    it "returns nil for a token signed with a different secret" do
      token = described_class.encode({ user_id: 42 }, secret: secret, ttl: 3600)

      expect(described_class.decode(token, secret: "wrong-secret")).to be_nil
    end

    it "returns nil for an expired token" do
      token = described_class.encode({ user_id: 42 }, secret: secret, ttl: -1)

      expect(described_class.decode(token, secret: secret)).to be_nil
    end

    it "returns nil for garbage input" do
      expect(described_class.decode("not-a-token", secret: secret)).to be_nil
    end
  end
end
