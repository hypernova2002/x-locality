# frozen_string_literal: true

require "factory_bot"

# FactoryBot's create strategy calls #save! (ActiveRecord convention).
# Sequel::Model#save already raises on failure by default
# (raise_on_save_failure), so this is an exact alias, not a shim.
Sequel::Model.class_eval do
  alias_method :save!, :save unless method_defined?(:save!)
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
