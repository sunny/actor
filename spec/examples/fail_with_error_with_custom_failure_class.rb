# frozen_string_literal: true

class FailWithErrorWithCustomFailureClass < Actor
  self.failure_class = MyCustomFailure

  def call
    fail!(error: "Ouch", some_other_key: 42)
  end
end
