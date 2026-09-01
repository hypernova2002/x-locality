# frozen_string_literal: true

require 'webmock/rspec'

# No spec should ever hit a real LLM provider - every adapter call must be
# stubbed or doubled.
WebMock.disable_net_connect!(allow_localhost: true)
