# frozen_string_literal: true

class SucceedEarly < Actor
  def call
    succeed!

    raise 'Should never be called'
  end
end
