# frozen_string_literal: true

class UseUnknownInput < Actor
  input :name, default: 'Jim'

  def call
    context.foobar
  end
end
