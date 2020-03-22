# frozen_string_literal: true

class DisallowNilOnInputWithDeprecatedRequired < Actor
  input :name, type: String, required: true

  def call; end
end
