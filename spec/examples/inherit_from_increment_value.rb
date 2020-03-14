# frozen_string_literal: true

class InheritFromIncrementValue < IncrementValue
  input :name, type: 'String'

  def call
    super

    context.value += 1
  end
end
