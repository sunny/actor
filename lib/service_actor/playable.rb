# frozen_string_literal: true

module ServiceActor
  # Play class method to call a series of actors with the same result. On
  # failure, calls rollback on any actor that succeeded.
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

        play_actors.each do |actor|
          child.play_actors << actor
        end
      end

      def play(*actors, **options)
        actors.each do |actor|
          play_actors.push({ actor: actor, **options })
        end
      end

      def play_actors
        @play_actors ||= []
      end
    end

    module PrependedMethods
      def call
        self.class.play_actors.each do |options|
          next if options[:if] && !options[:if].call(result)

          play_actor(options[:actor])
        end
      rescue Failure
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

      private

      def play_actor(actor)
        if actor.is_a?(Class) && actor.ancestors.include?(Actor)
          actor = actor.new(result)
          actor._call
        else
          actor.call(result)
        end

        (@played ||= []).unshift(actor)
      end
    end
  end
end
