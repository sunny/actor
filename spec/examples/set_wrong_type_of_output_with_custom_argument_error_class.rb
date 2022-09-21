# frozen_string_literal: true

class SetWrongTypeOfOutputWithCustomArgumentErrorClass < ApplicationService
  output :name, type: String

  def call
    self.name = 42
  end
end
