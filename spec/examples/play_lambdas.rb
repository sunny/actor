# frozen_string_literal: true

class PlayLambdas < Actor
  output :name, type: 'String'

  play ->(ctx) { ctx.value = 3 },
       IncrementValue,
       ->(ctx) { ctx.name = "Jim number #{ctx.value}" },
       SetNameToDowncase
end
