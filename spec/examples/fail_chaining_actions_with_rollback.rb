# frozen_string_literal: true

class FailChainingActionsWithRollback < Actor
  input :value, type: 'Integer'
  output :value, type: 'Integer'
  output :name, type: 'String'

  play AddNameToContext,
       IncrementValueWithRollback,
       IncrementValueWithRollback,
       FailWithError,
       IncrementValueWithRollback
end
