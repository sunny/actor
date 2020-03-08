# frozen_string_literal: true

class FailWithError < Actor
  def call
    fail!(error: 'Ouch', some_other_key: 42)
  end
end
