# frozen_string_literal: true

class PlayActors < Actor
  input :value, type: 'Integer'
  output :value, type: 'Integer'
  output :name, type: 'String'

  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       IncrementValue
end
