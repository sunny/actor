# frozen_string_literal: true

module ServiceActor
  # Raised when an input or output does not match the given conditions.
  class ArgumentError < ServiceActor::Error; end
end
