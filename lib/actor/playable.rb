# frozen_string_literal: true

class Actor
  # DSL to call a series of actors with the same context. On failure, calls
  # rollback on any actor that succeeded.
  #
  #   class CreateUser < Actor
  #     play SaveUser,
  #          CreateSettings,
  #          SendWelcomeEmail
  #   end
  module Playable
    def self.included(base)
      base.extend(ClassMethods)
      base.prepend(PrependedMethods)
    end

    module ClassMethods
      def play(*play_actors)
        @play_actors = play_actors
      end

      def play_actors
        @play_actors ||= []
      end
    end

    module PrependedMethods
      def call
        super

        self.class.play_actors.each do |actor|
          if actor.respond_to?(:call_with_context)
            actor = actor.call_with_context(context)
          else
            actor.call(context)
          end

          (@played_actors ||= []).unshift(actor)
        end
      rescue Actor::Failure
        rollback
        raise
      end

      def rollback
        super

        (@played_actors || []).each do |actor|
          next unless actor.respond_to?(:rollback)

          actor.rollback
        end
      end
    end
  end
end
