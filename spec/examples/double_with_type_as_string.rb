# frozen_string_literal: true

class DoubleWithTypeAsString < Actor
  input :value, type: [Integer, 'Float']
  output :double

  def call
    self.double = value * value
  end
end
