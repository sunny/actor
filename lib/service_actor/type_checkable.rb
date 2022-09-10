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
#             message: (lambda do |_kind, input_key, _service_name, actual_type_name, expected_type_names| # rubocop:disable Layout/LineLength
#               "Wrong type `#{actual_type_name}` for `#{input_key}`. " \
#               "Expected: `#{expected_type_names}`"
#             end)
#           }
#   end
module ServiceActor::TypeCheckable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    DEFAULT_MESSAGE = lambda do
      |kind, input_key, service_name, actual_type_name, expected_type_names|

      "#{kind} #{input_key} on #{service_name} must be of type " \
      "#{expected_type_names} but was #{actual_type_name}"
    end

    private_constant :DEFAULT_MESSAGE

    def _call
      check_type_definitions(self.class.inputs, kind: "Input")

      super

      check_type_definitions(self.class.outputs, kind: "Output")
    end

    private

    def check_type_definitions(definitions, kind:) # rubocop:disable Metrics/MethodLength
      definitions.each do |key, options|
        type_definition = options[:type] || next
        value = result[key] || next

        base_arguments = {
          kind: kind,
          input_key: key,
          service_name: self.class,
          actual_type_name: value.class
        }

        types, message = define_types_with(type_definition)

        next if types.any? { |type| value.is_a?(type) }

        raise_error_with(
          message,
          **base_arguments,
          expected_type_names: types.join(", "),
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
