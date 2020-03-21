# frozen_string_literal: true

class SetOutputCalledDisplay < Actor
  output :display

  def call
    self.display = 'Foobar'
  end
end
