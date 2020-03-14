# frozen_string_literal: true

class SetOutputCalledDisplay < Actor
  output :display

  def call
    context.display = 'Foobar'
  end
end
