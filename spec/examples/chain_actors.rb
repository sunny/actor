# frozen_string_literal: true

class ChainActors < Actor
  input :value, type: 'Integer'
  output :value, tpye: 'String'
  output :name, tpye: 'String'

  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       IncrementValue
end
