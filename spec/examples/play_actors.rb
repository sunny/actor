# frozen_string_literal: true

require_relative "./increment_value"
require_relative "./do_nothing"
require_relative "./add_name_to_context"
require_relative "./set_name_to_downcase"
require_relative "./use_stripped_down_actor"

class PlayActors < Actor
  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       UseStrippedDownActor,
       IncrementValue
end
