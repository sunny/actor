# frozen_string_literal: true

# Adds `type:` checking to inputs and outputs. Accepts class names or classes
# that should match an ancestor. Also accepts arrays.
#
# Example:
#
#   class ReduceOrderAmount < Actor
#     input :order, type: "Order"
#     input :amount, type: [Integer, Float]
#     input :bonus_applied, type: [TrueClass FalseClass]
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

    def check_type_definitions(definitions, kind:)
      definitions.each do |key, options|
        type_definition = options[:type] || next
        value = result[key] || next

        types = types_for_definition(type_definition)
        next if types.any? { |type| value.is_a?(type) }

        raise ServiceActor::ArgumentError,
              "#{kind} #{key} on #{self.class} must be of type " \
              "#{types.join(', ')} but was #{value.class}"
      end
    end

    def types_for_definition(type_definition)
      Array(type_definition).map do |name|
        name.is_a?(String) ? Object.const_get(name) : name
      end
    end
  end
end
