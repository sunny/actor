# frozen_string_literal: true

class ChainActors < Actor
  input :value
  output :value
  output :name

  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       IncrementValue
end
