# frozen_string_literal: true

require "spec_helper"

RSpec.describe Backend::Auth::Signup do
  describe "#call" do
    it "creates an account and an owner user" do
      result = described_class.new.call(
        account_name: "Acme Inc", email: "dan@acme.test", password: "supersecret123"
      )

      expect(result).to be_success
      user = result.value!
      expect(user.email).to eq("dan@acme.test")
      expect(user.role).to eq("owner")
      expect(user.account.name).to eq("Acme Inc")
    end

    it "hashes the password, never storing it in plaintext" do
      user = described_class.new.call(
        account_name: "Acme Inc", email: "dan@acme.test", password: "supersecret123"
      ).value!

      expect(user.password_digest).not_to eq("supersecret123")
      expect(user.authenticate("supersecret123")).to eq(user)
    end

    it "fails with :conflict when the email is already taken" do
      create(:user, email: "dan@acme.test")

      result = described_class.new.call(
        account_name: "Acme Inc", email: "dan@acme.test", password: "supersecret123"
      )

      expect(result).to be_failure
      code, detail = result.failure
      expect(code).to eq(:conflict)
      expect(detail).to match(/already in use/)
    end

    it "does not create an account when the email is taken" do
      create(:user, email: "dan@acme.test")

      expect do
        described_class.new.call(account_name: "Acme Inc", email: "dan@acme.test", password: "supersecret123")
      end.not_to change(Backend::Models::Account, :count)
    end
  end
end
