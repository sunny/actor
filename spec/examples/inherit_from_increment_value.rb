# frozen_string_literal: true

require_relative './increment_value'

class InheritFromIncrementValue < IncrementValue
  def call
    super

    context.value += 1
  end
end
