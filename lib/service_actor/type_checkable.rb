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
#     input :bonus_applied,
#           type: {
#             class_name: [TrueClass, FalseClass],
#             message: (lambda do |_kind, input_key, _service_name, expected_type_names, actual_type_name|
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
    def _call
      check_type_definitions(self.class.inputs, kind: "Input")

      super

      check_type_definitions(self.class.outputs, kind: "Output")
    end

    private

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def check_type_definitions(definitions, kind:)
      definitions.each do |key, options|
        type_definition = options[:type] || next
        value = result[key] || next

        message = "#{kind} #{key} on #{self.class} must be of type " \
                  "#{types.join(', ')} but was #{value.class}"

        if type_definition.is_a?(Hash) # advanced mode
          type_definition, message =
            type_definition.values_at(:class_name, :message)
        end

        types = types_for_definition(type_definition)

        next if types.any? { |type| value.is_a?(type) }

        error_text =
          if message.is_a?(Proc)
            message.call(kind, key, self.class, types.join(", "), value.class)
          else
            message
          end

        raise ServiceActor::ArgumentError, error_text
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def types_for_definition(type_definition)
      Array(type_definition).map do |name|
        name.is_a?(String) ? Object.const_get(name) : name
      end
    end
  end
end
