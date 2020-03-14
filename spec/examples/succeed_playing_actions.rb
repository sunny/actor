# frozen_string_literal: true

class SucceedPlayingActions < Actor
  input :value, type: 'Integer'
  output :value, type: 'String'

  play ->(ctx) { ctx.count = 1 },
       SucceedEarly,
       ->(ctx) { ctx.count = 2 }
end
