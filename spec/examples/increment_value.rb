# frozen_string_literal: true

class IncrementValue < Actor
  input :value, type: 'Integer'
  output :value, type: 'Integer'

  def call
    context.value += 1
  end
end
