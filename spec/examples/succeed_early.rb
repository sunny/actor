# frozen_string_literal: true

# DEPRECATED
class SucceedEarly < Actor
  def call
    succeed!

    raise 'Should never be called'
  end
end
