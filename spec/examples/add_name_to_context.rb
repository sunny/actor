# frozen_string_literal: true

class AddNameToContext < Actor
  output :name, type: 'String'

  def call
    context.name = 'Jim'
  end
end
