# frozen_string_literal: true

require_relative "./add_name_to_context"
require_relative "./increment_value"
require_relative "./fail_with_error"

class PlayMultipleTimesWithEvaluatedConditions < Actor
  input :callable
  input :value, default: 1

  play -> actor { actor.value += 1 },
       -> actor { actor.value += 1 },
       -> actor { actor.value += 1 },
       if: -> actor { actor.callable.call }
end
