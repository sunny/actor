# frozen_string_literal: true

require_relative './succeed_early'

# DEPRECATED
class SucceedPlayingActions < Actor
  play ->(result) { result.count = 1 },
       SucceedEarly,
       ->(result) { result.count = 2 }
end
