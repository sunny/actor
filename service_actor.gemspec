# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'actor/version'

Gem::Specification.new do |spec|
  spec.name = 'service_actor'
  spec.version = Actor::VERSION

  spec.require_paths = ['lib']
  spec.authors = ['Sunny Ripert']
  spec.email = ['sunny@sunfox.org']

  spec.summary = 'Service objects for your application logic'
  spec.description = 'Service objects for your application logic'
  spec.licenses = ['MIT']

  spec.homepage = 'https://github.com/sunny/actor'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.extra_rdoc_files = %w[
    LICENSE.txt
    README.md
  ]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z lib`.split("\x0")
  end

  # Tests
  spec.add_development_dependency 'rspec'

  # Development Tasks
  spec.add_development_dependency 'rake'

  # Debugger
  spec.add_development_dependency 'pry'

  # Linting
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
end
