# frozen_string_literal: true

class AddNameToContext < Actor
  output :name, type: String

  def call
    self.name = "Jim"
  end
end
