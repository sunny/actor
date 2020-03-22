# frozen_string_literal: true

require 'service_actor/core'

# Exceptions
require 'service_actor/error'
require 'service_actor/failure'
require 'service_actor/success'
require 'service_actor/argument_error'

# Core
require 'service_actor/result'
require 'service_actor/attributable'
require 'service_actor/playable'
require 'service_actor/core'

# Concerns
require 'service_actor/defaultable'
require 'service_actor/type_checkable'
require 'service_actor/nil_checkable'
require 'service_actor/conditionable'

module ServiceActor
  module Base
    def self.included(base)
      # Core
      base.include(Core)

      # Concerns
      base.include(Defaultable)
      base.include(TypeCheckable)
      base.include(NilCheckable)
      base.include(Conditionable)
    end
  end
end
