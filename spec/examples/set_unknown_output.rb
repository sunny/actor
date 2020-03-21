# frozen_string_literal: true

class SetUnknownOutput < Actor
  output :name

  def call
    self.foobar = 42
  end
end
