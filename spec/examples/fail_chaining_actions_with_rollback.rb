# frozen_string_literal: true

class FailChainingActionsWithRollback < Actor
  input :value
  output :value
  output :name

  play AddNameToContext,
       IncrementValueWithRollback,
       IncrementValueWithRollback,
       FailWithError,
       IncrementValueWithRollback
end
