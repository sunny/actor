# frozen_string_literal: true

class SetWrongTypeOfOutputWithCustomArgumentErrorClass < Actor
  self.argument_error_class = MyCustomArgumentError

  output :name, type: String

  def call
    self.name = 42
  end
end
