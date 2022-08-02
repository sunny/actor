# frozen_string_literal: true

class PlayMultipleTimes < Actor
  input :value, default: 1
  output :value
  output :name

  play IncrementValue,
       DoNothing

  play AddNameToContext,
       SetNameToDowncase

  play IncrementValue
end
