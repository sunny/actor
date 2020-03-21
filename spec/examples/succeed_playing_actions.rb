# frozen_string_literal: true

require_relative './succeed_early'

class SucceedPlayingActions < Actor
  play ->(ctx) { ctx.count = 1 },
       SucceedEarly,
       ->(ctx) { ctx.count = 2 }
end
