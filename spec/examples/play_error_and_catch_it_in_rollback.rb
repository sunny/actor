# frozen_string_literal: true

class PlayErrorAndCatchItInRollback < Actor
  play CatchErrorInRollback,
       FailWithError
end
