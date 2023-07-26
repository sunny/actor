# frozen_string_literal: true

class PlayLambdas < Actor
  output :name, type: String

  play -> actor { actor.value = 3 },
       IncrementValue,
       -> actor { actor.name = "Jim number #{actor.value}" },
       -> _ { {name: "Does nothing"} },
       SetNameToDowncase
end
