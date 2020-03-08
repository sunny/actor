# frozen_string_literal: true

class FailChainingActionsWithRollback < Actor
  play AddNameToContext,
       IncrementValueWithRollback,
       IncrementValueWithRollback,
       FailWithError,
       IncrementValueWithRollback
end
