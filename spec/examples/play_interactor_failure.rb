# frozen_string_literal: true

class PlayInteractorFailure < Actor
  input :value, default: 1
  output :value

  play IncrementValueWithInteractor,
       FailWithInteractor,
       IncrementValueWithInteractor
end
