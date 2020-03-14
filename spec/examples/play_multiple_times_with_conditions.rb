# frozen_string_literal: true

class PlayMultipleTimesWithConditions < Actor
  input :value, default: 1

  play AddNameToContext

  play IncrementValue,
       IncrementValue,
       if: ->(ctx) { ctx.name == 'Jim' }

  play FailWithError,
       if: ->(_ctx) { false }
end
