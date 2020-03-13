# frozen_string_literal: true

class FailChainingActions < Actor
  input :value, type: 'Integer'
  output :value, type: 'String'

  play IncrementValue,
       IncrementValue,
       FailWithError,
       IncrementValue
end
