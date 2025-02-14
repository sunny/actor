# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec"
end

require "bundler/setup"
require "service_actor"
require "pry"

Dir["#{__dir__}/support/**/*.rb"].each { |path| require path }

# Autoload examples
loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path("examples", __dir__))
loader.setup

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def engine_mri?
  RUBY_ENGINE == "ruby"
end
