# frozen_string_literal: true

class FailChainingActions < Actor
  play IncrementValue,
       IncrementValue,
       FailWithError,
       IncrementValue
end
