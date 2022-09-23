# frozen_string_literal: true

# Core
require "service_actor/core"
require "service_actor/raisable"
require "service_actor/attributable"
require "service_actor/playable"
require "service_actor/result"

# Exceptions
require "service_actor/error"
require "service_actor/failure"
require "service_actor/argument_error"

# Concerns
require "service_actor/type_checkable"
require "service_actor/nil_checkable"
require "service_actor/conditionable"
require "service_actor/collectionable"
require "service_actor/defaultable"
require "service_actor/failable"

module ServiceActor
  module Base
    def self.included(base)
      # Essential mechanics
      base.include(ServiceActor::Core)
      base.include(ServiceActor::Raisable)
      base.include(ServiceActor::Attributable)
      base.include(ServiceActor::Playable)

      # Extra concerns
      base.include(ServiceActor::TypeCheckable)
      base.include(ServiceActor::NilCheckable)
      base.include(ServiceActor::Conditionable)
      base.include(ServiceActor::Collectionable)
      base.include(ServiceActor::Defaultable)
      base.include(ServiceActor::Failable)
    end
  end
end
