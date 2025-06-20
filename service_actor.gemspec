# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "service_actor/version"

Gem::Specification.new do |spec|
  spec.name = "service_actor"
  spec.version = ServiceActor::VERSION

  spec.authors = ["Sunny Ripert"]
  spec.email = ["sunny@sunfox.org"]

  spec.summary = "Service objects for your application logic"
  spec.description = "Service objects for your application logic"
  spec.licenses = ["MIT"]

  spec.homepage = "https://github.com/sunny/actor"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = %w[
    LICENSE.txt
    README.md
  ]

  files = %w[git ls-files -z lib]
  spec.files = IO.popen(files, chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true)
  end

  spec.required_ruby_version = ">= 3.2"

  # Loader
  spec.add_runtime_dependency "zeitwerk", ">= 1.0"

  # Tests
  spec.add_development_dependency "rspec", ">= 3.0"

  # Development Tasks
  spec.add_development_dependency "rake", ">= 13.0"

  # Debugger
  spec.add_development_dependency "pry", ">= 0.12"

  # Linting rubocop-lts is a RuboCop wrapper for Ruby
  #   and should only be bumped when dropping old Ruby support
  # see: https://rubocop-lts.gitlab.io/HOW_TO_UPGRADE_RUBY/
  spec.add_development_dependency "rubocop-lts", "~> 24.0"

  # rubocop-lts dependency. Can be removed when RuboCop LTS is upgraded.
  # https://github.com/sunny/actor/pull/126#issuecomment-1966682674
  spec.add_development_dependency "standard-rubocop-lts", ">= 1.0.10"

  # Update RuboCop rules gradually.
  # rubocop-lts dependency. Can be removed when RuboCop LTS is upgraded.
  spec.add_development_dependency "rubocop-gradual", ">= 0.3"

  # Lint RSpec code
  spec.add_development_dependency "rubocop-rspec", ">= 2.0"

  # Add performance linting
  spec.add_development_dependency "rubocop-performance", ">= 1.0"

  # Add Rakefile linting
  spec.add_development_dependency "rubocop-rake", ">= 0.1"

  # Thread-safety checks
  spec.add_development_dependency "rubocop-thread_safety", ">= 0.1"

  # Formatter for GitHub’s code scanning
  spec.add_development_dependency "code-scanning-rubocop", ">= 0.6"

  # For testing Interactor migration support
  spec.add_development_dependency "interactor", ">= 3.0"

  # Code coverage reporter
  spec.add_development_dependency "simplecov", ">= 0.0"

  # https://github.com/ruby/ruby/pull/12531
  spec.add_development_dependency "ostruct", ">= 0.0"
end
