# frozen_string_literal: true

class UseRequiredInput < Actor
  input :name, type: 'String', required: true

  def call; end
end
