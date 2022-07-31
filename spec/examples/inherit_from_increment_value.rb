# frozen_string_literal: true

class InheritFromIncrementValue < IncrementValue
  def call
    super

    self.value += 1
  end
end
