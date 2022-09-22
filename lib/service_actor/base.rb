# frozen_string_literal: true

require "service_actor/support/loader"

module ServiceActor::Base
  def self.included(base)
    # Essential mechanics
    base.include(ServiceActor::Core)
    base.include(ServiceActor::Raisable)
    base.include(ServiceActor::Attributable)
    base.include(ServiceActor::Playable)

    # Extra concerns
    base.include(ServiceActor::TypeCheckable)
    base.include(ServiceActor::NilCheckable)
    base.include(ServiceActor::Conditionable)
    base.include(ServiceActor::Collectionable)
    base.include(ServiceActor::Defaultable)
    base.include(ServiceActor::Failable)
  end
end
