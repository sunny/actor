# frozen_string_literal: true

class InheritFromIncrementValue < IncrementValue
  def call
    super

    context.value += 1
  end
end
