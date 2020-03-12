# frozen_string_literal: true

class FailChainingActions < Actor
  input :value
  output :value

  play IncrementValue,
       IncrementValue,
       FailWithError,
       IncrementValue
end
