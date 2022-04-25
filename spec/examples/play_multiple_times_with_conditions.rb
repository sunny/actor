# frozen_string_literal: true

require_relative "./add_name_to_context"
require_relative "./increment_value"
require_relative "./fail_with_error"

class PlayMultipleTimesWithConditions < Actor
  input :value, default: 1

  play AddNameToContext

  play IncrementValue,
       IncrementValue,
       if: ->(result) { result.name == "Jim" }

  play FailWithError,
       if: ->(_result) { false }
end
