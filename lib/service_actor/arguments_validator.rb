# frozen_string_literal: true

module ServiceActor::ArgumentsValidator
  module_function

  def validate_origin_name(name, origin:)
    return unless ServiceActor::Result.instance_methods.include?(name.to_sym)

    Kernel.warn(
      "DEPRECATED: Defining inputs, outputs or alias_input that collide with " \
      "`ServiceActor::Result` instance methods will lead to runtime errors " \
      "in the next major release of Actor. " \
      "Problematic #{origin}: `#{name}`",
    )
  end

  def validate_error_class(value)
    return if value.is_a?(Class) && value <= Exception

    raise ArgumentError, "Expected #{value} to be a subclass of Exception"
  end
end
