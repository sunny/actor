# frozen_string_literal: true

if ENV["COVERAGE"] != "false"
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch
    add_filter "/spec"
  end
end
