# frozen_string_literal: true

class ExampleApplicationActor
  include ServiceActor::Base
end

class InheritFromCustomBase < ExampleApplicationActor
  input :value, type: Integer
  output :value, type: Integer

  def call
    self.value += 1
  end
end
