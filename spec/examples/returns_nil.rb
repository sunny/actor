# frozen_string_literal: true

class ReturnsNil < Actor
  input :call_counter

  def call
    call_counter.trigger

    nil
  end
end
