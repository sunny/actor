# frozen_string_literal: true

class AddNameToContext < Actor
  output :name

  def call
    context.name = 'Jim'
  end
end
