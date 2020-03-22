# frozen_string_literal: true

# Exceptions
require 'actor/error'
require 'actor/failure'
require 'actor/success'
require 'actor/argument_error'

# Base
require 'actor/base'
require 'actor/result'

# Modules
require 'actor/defaultable'
require 'actor/type_checkable'
require 'actor/nil_checkable'
require 'actor/conditionable'

class Actor
  include Actor::Base
  include Actor::Defaultable
  include Actor::TypeCheckable
  include Actor::NilCheckable
  include Actor::Conditionable
end
