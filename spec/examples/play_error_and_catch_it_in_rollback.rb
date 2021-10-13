# frozen_string_literal: true

require_relative './catch_error_in_rollback'
require_relative './fail_with_error'

class PlayErrorAndCatchItInRollback < Actor
  play CatchErrorInRollback,
       FailWithError
end
