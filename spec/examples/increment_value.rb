# frozen_string_literal: true

class IncrementValue < Actor
  input :value, type: Integer, default: 0
  output :value, type: Integer

  def call
    self.value += 1
  end
end
