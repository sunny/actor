# frozen_string_literal: true

class PlayInstanceMethods < Actor
  output :value, type: Integer
  output :name, type: String

  play :set_value,
       IncrementValue,
       :set_name,
       :do_nothing,
       SetNameToDowncase

  private

  def set_value
    self.value = 3
  end

  def set_name
    self.name = "Jim number #{value}"
  end

  def do_nothing
    {name: "Does nothing"}
  end
end
