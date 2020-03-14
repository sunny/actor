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
      def inherited(child)
        super

        child.play(*play_actors)
      end

      def play(*actors)
        @play_actors ||= []
        @play_actors += actors
      end

      def play_actors
        @play_actors ||= []
      end
    end

    module PrependedMethods
      def call
        self.class.play_actors.each do |actor|
          if actor.respond_to?(:new)
            actor = actor.new(@context)
            actor.run
          else
            actor.call(@context)
          end

          (@played ||= []).unshift(actor)
        end
      rescue Actor::Failure
        rollback
        raise
      end

      def rollback
        return unless @played

        @played.each do |actor|
          next unless actor.respond_to?(:rollback)

          actor.rollback
        end
      end
    end
  end
end
