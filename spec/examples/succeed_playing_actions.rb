# frozen_string_literal: true

class SucceedPlayingActions < Actor
  play ->(ctx) { ctx.count = 1 },
       SucceedEarly,
       ->(ctx) { ctx.count = 2 }
end
