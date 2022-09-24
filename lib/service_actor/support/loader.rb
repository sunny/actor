# frozen_string_literal: true

require "zeitwerk"

module ServiceActor; end

lib = File.expand_path("../..", __dir__)

loader = Zeitwerk::Loader.new
loader.tag = "service_actor"
loader.inflector = Zeitwerk::GemInflector.new(
  File.expand_path("service_actor.rb", lib),
)
loader.push_dir(lib)
loader.ignore(__dir__)
loader.setup
