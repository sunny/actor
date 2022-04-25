# frozen_string_literal: true

source "https://rubygems.org"

gemspec

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.5")
  # Here because v1.13 requires ruby version >= 2.5.
  gem "rubocop", "< 1.13"

  # Here because v1.11.0 requires ruby version >= 2.5.
  gem "rubocop-performance", "< 1.11.0"

  # Here because v2.3.0 requires ruby version >= 2.5.
  gem "rubocop-rspec", "< 2.3.0"

  # RuboCop dependency
  # Here because v1.21.0 requires ruby version >= 2.5.
  gem "parallel", "< 1.21"

  # RuboCop dependency
  # Here because v1.4.2 requires ruby version >= 2.5.
  gem "rubocop-ast", "< 1.4.2"
end
