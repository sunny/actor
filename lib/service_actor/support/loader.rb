# frozen_string_literal: true

module ServiceActor; end

if defined?(ServiceActor::AUTOLOADERS)
  require "zeitwerk"

  lib = File.expand_path("../..", __dir__)

  loader = Zeitwerk::Loader.new
  loader.tag = "service_actor"
  loader.inflector = Zeitwerk::GemInflector.new(
    File.expand_path("service_actor.rb", lib),
  )
  loader.push_dir(lib)
  loader.ignore(__dir__)
  loader.setup

  ServiceActor::AUTOLOADERS << loader
else
  require "service_actor/support/basic_loader"
end
