# frozen_string_literal: true

class PlayMultipleTimesWithConditions < Actor
  input :value, default: 1

  play AddNameToContext

  play IncrementValue,
       IncrementValue,
       if: -> actor { actor.name == "Jim" }

  play FailWithError,
       if: -> _ { false }
end
