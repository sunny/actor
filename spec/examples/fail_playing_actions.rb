# frozen_string_literal: true

require_relative "./increment_value"
require_relative "./fail_with_error"

class FailPlayingActions < Actor
  input :value, type: Integer
  output :value, type: String

  play IncrementValue,
       IncrementValue,
       FailWithError,
       IncrementValue
end
