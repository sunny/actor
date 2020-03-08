# frozen_string_literal: true

class IncrementValue < Actor
  input :value
  output :value

  def call
    context.value += 1
  end
end
