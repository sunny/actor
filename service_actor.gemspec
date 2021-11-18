# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'service_actor/version'

Gem::Specification.new do |spec|
  spec.name = 'service_actor'
  spec.version = ServiceActor::VERSION

  spec.authors = ['Sunny Ripert']
  spec.email = ['sunny@sunfox.org']

  spec.summary = 'Service objects for your application logic'
  spec.description = 'Service objects for your application logic'
  spec.licenses = ['MIT']

  spec.homepage = 'https://github.com/sunny/actor'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.require_paths = ['lib']
  spec.extra_rdoc_files = %w[
    LICENSE.txt
    README.md
  ]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z lib`.split("\x0")
  end

  spec.required_ruby_version = ['>= 2.4']

  # Tests
  spec.add_development_dependency 'rspec'

  # Development Tasks
  spec.add_development_dependency 'rake'

  # Debugger
  spec.add_development_dependency 'pry'

  # Linting
  spec.add_development_dependency 'rubocop'

  # Lint RSpec code
  spec.add_development_dependency 'rubocop-rspec'

  # Add performance linting
  spec.add_development_dependency 'rubocop-performance'

  # Formatter for GitHub’s code scanning
  spec.add_development_dependency 'code-scanning-rubocop'

  # For testing Interactor migration support
  spec.add_development_dependency 'interactor'
end
