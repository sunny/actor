# frozen_string_literal: true

class ChainActions < Actor
  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       IncrementValue
end
