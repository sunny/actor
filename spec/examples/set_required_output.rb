# frozen_string_literal: true

class SetRequiredOutput < Actor
  output :name, required: true

  def call
    context.name = 'Jim'
  end
end
