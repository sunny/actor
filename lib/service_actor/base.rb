# frozen_string_literal: true

# Exceptions
require 'service_actor/error'
require 'service_actor/failure'
require 'service_actor/argument_error'

# Core
require 'service_actor/core'
require 'service_actor/attributable'
require 'service_actor/playable'
require 'service_actor/result'

# Concerns
require 'service_actor/type_checkable'
require 'service_actor/nil_checkable'
require 'service_actor/conditionable'
require 'service_actor/defaultable'
require 'service_actor/collectionable'
require 'service_actor/failable'

module ServiceActor
  module Base
    def self.included(base)
      # Core
      base.include(Core)
      base.include(Attributable)
      base.include(Playable)

      # Concerns
      base.include(TypeCheckable)
      base.include(NilCheckable)
      base.include(Conditionable)
      base.include(Collectionable)
      base.include(Defaultable)
      base.include(Failable)
    end
  end
end
