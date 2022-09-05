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

    def check_type_definitions(definitions, kind:) # rubocop:disable Metrics/MethodLength
      definitions.each do |key, options|
        type_definition = options[:type] || next
        value = result[key] || next

        # FIXME: The `prototype_3_with` method needs to be renamed.
        types, message = prototype_3_with(
          type_definition,
          kind: kind,
          input_key: key,
          service_name: self.class,
          actual_type_name: value.class,
        )

        next if types.any? { |type| value.is_a?(type) }

        raise_error_with(
          message,
          kind: kind,
          input_key: key,
          service_name: self.class,
          expected_type_names: types.join(", "),
          actual_type_name: value.class,
        )
      end
    end

    # FIXME: The `prototype_3_with` method needs to be renamed.
    def prototype_3_with( # rubocop:disable Metrics/MethodLength
      type_definition,
      kind:,
      input_key:,
      service_name:,
      actual_type_name:
    ) # do
      if type_definition.is_a?(Hash) # advanced mode
        type_definition, message =
          type_definition.values_at(:class_name, :message)
        types = types_for_definition(type_definition)
      else
        types = types_for_definition(type_definition)
        message = "#{kind} #{input_key} on #{service_name} must be of type " \
                  "#{types.join(', ')} but was #{actual_type_name}"
      end

      [
        types,
        message
      ]
    end

    def types_for_definition(type_definition)
      Array(type_definition).map do |name|
        name.is_a?(String) ? Object.const_get(name) : name
      end
    end
  end
end
