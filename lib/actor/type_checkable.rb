# frozen_string_literal: true

class Actor
  # Adds `type:` checking to inputs and outputs. Accepts strings that should
  # match an ancestor. Also accepts arrays.
  #
  # Example:
  #
  #   class ReduceOrderAmount < Actor
  #     input :order, type: 'Order'
  #     input :amount, type: %w[Integer Float]
  #     input :bonus_applied, type: %w[TrueClass FalseClass]
  #   end
  module TypeCheckable
    def before
      super

      check_type_definitions(self.class.inputs)
    end

    def after
      super

      check_type_definitions(self.class.outputs)
    end

    private

    def check_type_definitions(definitions)
      definitions.each do |key, options|
        type_definition = options[:type] || next
        value = context[key] || next

        types = Array(type_definition).map { |name| Object.const_get(name) }
        next if types.any? { |type| value.is_a?(type) }

        error = "Input #{key} on #{self.class} must be of type " \
                "#{types.join(', ')} but was #{value.class}"
        fail!(error: error)
      end
    end
  end
end
