# frozen_string_literal: true

class OutputIsMissing < Actor
  output :name, type: String, allow_nil: true

  def call
    # nothing
  end
end
