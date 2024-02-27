# frozen_string_literal: true

# Play class method to call a series of actors with the same result. On failure,
# calls rollback on actors that succeeded.
#
#   class CreateUser < Actor
#     play SaveUser,
#          CreateSettings,
#          SendWelcomeEmail
#   end
module ServiceActor::Playable
  def self.included(base)
    base.extend(ClassMethods)
    base.prepend(PrependedMethods)
  end

  module ClassMethods
    def play(*actors, **options)
      play_actors.push(actors: actors, **options)
    end

    def alias_input(**options)
      lambda do |actor|
        options.each do |new, original|
          define_alias_input(actor, new, original)
        end
      end
    end

    def play_actors
      @play_actors ||= []
    end

    def inherited(child)
      super

      child.play_actors.concat(play_actors)
    end

    private

    def define_alias_input(actor, new_input, original_input)
      actor[new_input] = actor.delete(original_input)
    end
  end

  module PrependedMethods
    def call
      self.class.play_actors.each do |options|
        next unless callable_actor?(options)

        options[:actors].each { |actor| play_actor(actor) }
      end
    rescue self.class.failure_class
      rollback
      raise
    end

    def rollback
      return unless defined?(@played_actors)

      @played_actors.each do |actor|
        next unless actor.respond_to?(:rollback)

        actor.rollback
      end
    end

    private

    def callable_actor?(options)
      return false if options[:if] && !options[:if].call(result)
      return false if options[:unless]&.call(result)

      true
    end

    def play_actor(actor)
      play_service_actor(actor) ||
        play_method(actor) ||
        play_interactor(actor) ||
        actor.call(result)
    end

    def play_service_actor(actor)
      return unless actor.is_a?(Class)
      return unless actor.ancestors.include?(ServiceActor::Core)

      actor = actor.new(result)
      actor._call

      (@played_actors ||= []).unshift(actor)
    end

    def play_method(actor)
      return unless actor.is_a?(Symbol)

      send(actor)

      true
    end

    def play_interactor(actor)
      return unless actor.is_a?(Class)
      return unless actor.ancestors.map(&:name).include?("Interactor")

      result.merge!(actor.call(result.to_h).to_h)
    end
  end
end
