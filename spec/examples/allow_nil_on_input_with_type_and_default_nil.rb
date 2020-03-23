# frozen_string_literal: true

class AllowNilOnInputWithTypeAndDefaultNil < Actor
  input :name, type: String, default: nil

  def call; end
end
