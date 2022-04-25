# frozen_string_literal: true

require_relative "./increment_value"

class InheritFromIncrementValue < IncrementValue
  def call
    super

    self.value += 1
  end
end
