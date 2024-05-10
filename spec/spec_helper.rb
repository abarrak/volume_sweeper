require 'simplecov'
require_relative 'support/coverage'
require_relative 'support/std_helper'

SimpleCovHelper.configure_formatter
SimpleCov.start

require 'volume_sweeper'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Support::StdHelper

  ENV["RACK_ENV"] = "test"
end
