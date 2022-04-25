# frozen_string_literal: true

require_relative "./increment_value"
require_relative "./do_nothing"
require_relative "./add_name_to_context"
require_relative "./set_name_to_downcase"

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
