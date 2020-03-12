# frozen_string_literal: true

class IncrementValueWithRollback < Actor
  input :value
  output :value

  def call
    context.value += 1
  end

  def rollback
    context.value -= 1
  end
end
