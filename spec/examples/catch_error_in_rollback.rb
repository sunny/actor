# frozen_string_literal: true

class CatchErrorInRollback < Actor
  output :called
  output :found_error

  def call
    self.called = true
  end

  def rollback
    self.found_error = "Found “#{result.error}”"
  end
end
