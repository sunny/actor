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
        return unless defined?(@played)

        @played.each do |actor|
          next unless actor.respond_to?(:rollback)

          actor.rollback
        end
      end

      private

      def play_actor(actor)
        play_service_actor(actor) ||
          play_interactor(actor) ||
          play_callable_actor(actor)
      end

      def play_service_actor(actor)
        return unless actor.is_a?(Class)
        return unless actor.ancestors.include?(ServiceActor::Core)

        actor = actor.new(result)
        actor._call

        (@played ||= []).unshift(actor)
      end

      def play_interactor(actor)
        return unless actor.is_a?(Class)
        return unless actor.ancestors.map(&:name).include?('Interactor')

        result.merge!(actor.call(result).to_h)
      end

      def play_callable_actor(actor)
        actor.call(result)
      end
    end
  end
end
