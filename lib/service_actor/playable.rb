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
  class << self
    def included(base)
      base.extend(ClassMethods)
      base.prepend(PrependedMethods)
    end
  end

  module ClassMethods
    def play(*actors, **options)
      play_actors.push(actors: actors, **options)
    end

    def alias_input(**options)
      options.each_key do |new|
        ServiceActor::ArgumentsValidator.validate_origin_name(
          new, origin: :alias
        )
      end

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
      actor[new_input] = actor.delete!(original_input)
    end
  end

  module PrependedMethods
    def call
      default_output = nil

      self.class.play_actors.each do |options|
        next unless callable_actor?(options)

        options[:actors].each do |actor|
          default_output = play_actor(actor)
        end
      end

      default_output
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
      if actor.is_a?(Class) && actor.ancestors.include?(ServiceActor::Core)
        play_service_actor(actor)
      elsif actor.is_a?(Symbol)
        play_method(actor)
      elsif actor.is_a?(Class) &&
          actor.ancestors.map(&:name).include?("Interactor")
        play_interactor(actor)
      else
        actor.call(result)
      end
    end

    def play_service_actor(actor)
      actor = actor.new(result)
      call_output = actor._call

      (@played_actors ||= []).unshift(actor)

      call_output
    end

    def play_method(actor)
      send(actor)
    end

    def play_interactor(actor)
      result.merge!(actor.call(result.to_h).to_h)
    end
  end
end
