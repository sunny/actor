# frozen_string_literal: true

class PlayMultipleTimesWithConditions < Actor
  input :value, default: 1

  play AddNameToContext

  play IncrementValue,
       if: -> actor { actor.name == "Jim" }

  play IncrementValue,
       unless: -> actor { actor.name == "Tom" }

  play FailWithError,
       if: -> _ { false }

  play FailWithError,
       unless: -> _ { true }
end
