# frozen_string_literal: true

class PlayInteractor < Actor
  input :value, default: 1
  output :value

  play IncrementValueWithInteractor,
       IncrementValueWithInteractor
end
