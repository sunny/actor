# frozen_string_literal: true

class PlayMultipleTimesWithEvaluatedConditions < Actor
  input :callable
  input :value, default: 1

  play -> actor { actor.value += 1 },
       -> actor { actor.value += 1 },
       -> actor { actor.value += 1 },
       if: -> actor { actor.callable.call }
end
