# frozen_string_literal: true

class FailPlayingActions < Actor
  input :value, type: 'Integer'
  output :value, type: 'String'

  play IncrementValue,
       IncrementValue,
       FailWithError,
       IncrementValue
end
