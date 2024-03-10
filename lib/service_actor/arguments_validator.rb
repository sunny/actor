# frozen_string_literal: true

module ServiceActor::ArgumentsValidator
  module_function

  def validate_error_class(value)
    return if value.is_a?(Class) && value <= Exception

    raise ArgumentError, "Expected #{value} to be a subclass of Exception"
  end
end
