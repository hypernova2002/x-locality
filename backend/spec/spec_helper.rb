# frozen_string_literal: true

require "pathname"
SPEC_ROOT = Pathname(__dir__).realpath.freeze

ENV["HANAMI_ENV"] ||= "test"
# Same Postgres instance/credentials as dev - just a different database, so
# specs never touch dev data.
ENV["DATABASE_URL"] = ENV.fetch("DATABASE_URL").sub(/x_locality_development\z/, "x_locality_test")

require "hanami/prepare"

# hanami/prepare sets up the app but leaves providers to start lazily on
# first container resolution. Every spec touches the DB (directly or via
# factories), so start it eagerly once here rather than relying on the
# first example to trigger it.
Hanami.app["db"]

SPEC_ROOT.glob("support/**/*.rb").sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt" if SPEC_ROOT.join("../tmp").directory?
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Every example runs inside a rolled-back transaction - no cleanup gem
  # needed, and no test can see another test's data.
  config.around do |example|
    Backend::Models::Account.db.transaction(rollback: :always) { example.run }
  end
end
