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

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z lib`.split("\x0")
  end

  spec.required_ruby_version = [">= 2.7"]

  # Loader
  spec.add_runtime_dependency "zeitwerk"

  # Tests
  spec.add_development_dependency "rspec"

  # Development Tasks
  spec.add_development_dependency "rake"

  # Debugger
  spec.add_development_dependency "pry"

  # Linting rubocop-lts is a rubocop wrapper for Ruby
  #   and should only be bumped when dropping old Ruby support
  # see: https://rubocop-lts.gitlab.io/HOW_TO_UPGRADE_RUBY/
  spec.add_development_dependency "rubocop-lts", "~> 18.2"

  # This is a rubocop-lts dependency. Can be removed once a new version
  # of rubocop-lts is released.
  spec.add_development_dependency "rspec-block_is_expected"

  # Lint RSpec code
  spec.add_development_dependency "rubocop-rspec"

  # Add performance linting
  spec.add_development_dependency "rubocop-performance"

  # Add Rakefile linting
  spec.add_development_dependency "rubocop-rake"

  # Formatter for GitHub’s code scanning
  spec.add_development_dependency "code-scanning-rubocop"

  # For testing Interactor migration support
  spec.add_development_dependency "interactor"
end
