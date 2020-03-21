# frozen_string_literal: true

class DisallowNilOnInput < Actor
  input :name, type: 'String', allow_nil: false

  def call; end
end
