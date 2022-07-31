# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.new
loader.tag = "service_actor"
loader.inflector =
  Zeitwerk::GemInflector.new(File.expand_path("../service_actor.rb", __dir__))
loader.push_dir(File.expand_path("..", __dir__))
loader.setup

module ServiceActor
  module Base
    def self.included(base)
      # Essential mechanics
      base.include(Core)
      base.include(Attributable)
      base.include(Playable)

      # Extra concerns
      base.include(TypeCheckable)
      base.include(NilCheckable)
      base.include(Conditionable)
      base.include(Collectionable)
      base.include(Defaultable)
      base.include(Failable)
    end
  end
end
