# frozen_string_literal: true

require_relative './add_name_to_context'
require_relative './increment_value_with_rollback'
require_relative './fail_with_error'

class FailPlayingActionsWithRollback < Actor
  input :value, type: Integer
  output :value, type: Integer
  output :name, type: String

  play AddNameToContext,
       IncrementValueWithRollback,
       IncrementValueWithRollback,
       FailWithError,
       IncrementValueWithRollback
end
