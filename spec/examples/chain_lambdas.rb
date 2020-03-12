# frozen_string_literal: true

class ChainLambdas < Actor
  output :name

  play ->(ctx) { ctx.value = 3 },
       IncrementValue,
       ->(ctx) { ctx.name = "Jim number #{ctx.value}" },
       SetNameToDowncase
end
