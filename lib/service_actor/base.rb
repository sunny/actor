# frozen_string_literal: true

require "service_actor/support/loader"

module ServiceActor::Base
  class << self
    def included(base)
      # Essential mechanics
      base.include(ServiceActor::Core)
      base.include(ServiceActor::Configurable)
      base.include(ServiceActor::Attributable)
      base.include(ServiceActor::Playable)

      # Extra concerns
      base.include(ServiceActor::Checkable)
      base.include(ServiceActor::Defaultable)
      base.include(ServiceActor::Failable)
    end
  end
end
