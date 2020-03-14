# frozen_string_literal: true

class UseUnknownInput < Actor
  input :name

  def call
    context.foobar
  end
end
