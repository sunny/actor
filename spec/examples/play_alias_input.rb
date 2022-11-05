# frozen_string_literal: true

class PlayAliasInput < Actor
  output :name, type: String

  play IncrementValue,
       -> actor { actor.orig_name = "Jim number #{actor.value}" },
       alias_input(name: :orig_name),
       SetNameToDowncase
end
