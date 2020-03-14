# frozen_string_literal: true

class SetWrongTypeOfOutput < Actor
  output :name, type: 'String'

  def call
    context.name = 42
  end
end
