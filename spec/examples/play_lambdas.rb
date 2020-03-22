# frozen_string_literal: true

require_relative './increment_value'
require_relative './set_name_to_downcase'

class PlayLambdas < Actor
  output :name, type: String

  play ->(ctx) { ctx.value = 3 },
       IncrementValue,
       ->(ctx) { ctx.name = "Jim number #{ctx.value}" },
       SetNameToDowncase
end
