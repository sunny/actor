# frozen_string_literal: true

module TypeCheckable
  def before
    super

    check_type_of(self.class.inputs)
  end

  def after
    super

    check_type_of(self.class.outputs)
  end

  def check_type_of(definitions)
    definitions.each do |key, options|
      type_definition = options[:type] || next
      value = @full_context[key] || next

      types = Array(type_definition).map { |name| Object.const_get(name) }
      next if types.any? { |type| value.is_a?(type) }

      error = "Input #{key} on #{self.class} must be of type " \
              "#{types.join(', ')} but was #{value.class}"
      fail!(error: error)
    end
  end
end
