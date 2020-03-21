# frozen_string_literal: true

class Actor
  # Raised when an input or output does not match the given conditions.
  class ArgumentError < Actor::Error; end
end
