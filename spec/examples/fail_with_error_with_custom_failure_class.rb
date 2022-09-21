# frozen_string_literal: true

class FailWithErrorWithCustomFailureClass < ApplicationServiceWithCustomClasses
  def call
    fail!(error: "Ouch", some_other_key: 42)
  end
end
