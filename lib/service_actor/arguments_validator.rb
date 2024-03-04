# frozen_string_literal: true

module ServiceActor::ArgumentsValidator
  module_function

  def validate_origin_name(name, origin:)
    return unless ServiceActor::Result.instance_methods.include?(name.to_sym)

    raise ArgumentError, <<~TXT
      Defined #{origin} \`#{name}\` collides with `ServiceActor::Result` instance method
    TXT
  end

  def validate_error_class(value)
    return if value.is_a?(Class) && value <= Exception

    raise ArgumentError, "Expected #{value} to be a subclass of Exception"
  end
end
