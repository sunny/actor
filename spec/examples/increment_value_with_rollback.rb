# frozen_string_literal: true

class IncrementValueWithRollback < Actor
  input :value, type: 'Integer'
  output :value, type: 'Integer'

  def call
    self.value += 1
  end

  def rollback
    self.value -= 1
  end
end
