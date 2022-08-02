# frozen_string_literal: true

class PlayActors < Actor
  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       UseStrippedDownActor,
       IncrementValue
end
