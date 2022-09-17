# frozen_string_literal: true

# Adds `type:` checking to inputs and outputs. Accepts class names or classes
# that should match an ancestor. Also accepts arrays.
#
# Example:
#
#   class ReduceOrderAmount < Actor
#     input :order, type: "Order"
#     input :amount, type: [Integer, Float]
#     input :bonus_applied, type: [TrueClass, FalseClass]
#   end
#
#   class ReduceOrderAmount < Actor
#     input :order, type: { is: Order, message: "Order is required" }
#     input :amount, type: { is: Integer, message: "Incorrect amount" }
#
#     input :bonus_applied,
#           type: {
#             is: [TrueClass, FalseClass],
#             message: (lambda do |origin:, input_key:, actor:, expected_type:, given_type:| # rubocop:disable Layout/LineLength
#               "Wrong type \"#{given_type}\" for \"#{input_key}\". " \
#               "Expected: \"#{expected_type}\""
#             end)
#           }
#   end
module ServiceActor::TypeCheckable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    DEFAULT_MESSAGE = lambda do
      |origin:, input_key:, actor:, expected_type:, given_type:|

      "The \"#{input_key}\" #{origin} on \"#{actor}\" must be of type " \
      "\"#{expected_type}\" but was \"#{given_type}\""
    end

    private_constant :DEFAULT_MESSAGE

    def _call
      check_type_definitions(self.class.inputs, origin: "input")

      super

      check_type_definitions(self.class.outputs, origin: "output")
    end

    private

    def check_type_definitions(definitions, origin:) # rubocop:disable Metrics/MethodLength
      definitions.each do |key, options|
        type_definition = options[:type] || next
        value = result[key] || next

        types, message = define_types_with(type_definition)

        next if types.any? { |type| value.is_a?(type) }

        raise_error_with(
          message,
          origin: origin,
          input_key: key,
          actor: self.class,
          expected_type: types.join(", "),
          given_type: value.class,
        )
      end
    end

    def define_types_with(type_definition)
      if type_definition.is_a?(Hash)
        type_definition, message =
          type_definition.values_at(:is, :message)
      else
        message = DEFAULT_MESSAGE
      end

      types = types_for_definition(type_definition)

      [types, message]
    end

    def types_for_definition(type_definition)
      Array(type_definition).map do |name|
        name.is_a?(String) ? Object.const_get(name) : name
      end
    end
  end
end
