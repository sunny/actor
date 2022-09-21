# frozen_string_literal: true

class SetWrongTypeOfOutputWithCustomArgumentErrorClass < ApplicationServiceWithCustomClasses
  output :name, type: String

  def call
    self.name = 42
  end
end
