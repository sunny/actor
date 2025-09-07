# frozen_string_literal: true

class UseStrippedDownActorTestApp
  include ServiceActor::Base
end

class UseStrippedDownActor < UseStrippedDownActorTestApp
  output :stripped_down_actor

  def call
    self.stripped_down_actor = true
  end
end

class PlayActors < Actor
  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       UseStrippedDownActor,
       IncrementValue
end
