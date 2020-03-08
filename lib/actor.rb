# frozen_string_literal: true

require 'actor/failure'
require 'actor/context'

# Service object that represents an action you want to introduce in your
# application. Your actors should start with a verb, inherit from Actor and
# implement a `call` method.
class Actor
  class << self
    # Call an actor with a given context.
    #
    #   CreateUser.call(name: 'Joe')
    def call(context = {}, **arguments)
      actor = new_with_context(context.merge!(arguments))
      actor.call
      actor.context
    end

    # Call an actor with a given context. Does not raise on failure.
    #
    #   CreateUser.call(name: 'Joe')
    def result(context = {}, **arguments)
      actor = new_with_context(context.merge!(arguments))
      actor.call
      actor.context
    rescue Actor::Failure
      actor.context
    end

    # :nodoc:
    def new_with_context(context)
      actor = new
      actor.context = Actor::Context.to_context(context)
      actor.apply_defaults
      actor
    end

    # protected :new_with_context

    # DSL to call a series of actors with the same context. On failure, calls
    # a rollback on any actor that succeeded.
    #
    #   class CreateUser < Actor
    #     play SaveUser,
    #          CreateSettings,
    #          SendWelcomeEmail
    #   end
    def play(*play_actors)
      @play_actors = play_actors
    end

    # :nodoc:
    def play_actors
      @play_actors ||= []
    end

    # DSL to document the accepted attributes.
    #
    #   class CreateUser < Actor
    #     input :name
    #   end
    def input(name, **arguments)
      @inputs ||= {}
      @inputs[:name] = arguments

      define_method(name) do
        context.public_send(name)
      end

      private name
    end

    # :nodoc:
    def inputs
      @inputs ||= []
    end

    # DSL to document the exposed attributes.
    #
    #   class CreateUser < Actor
    #     output :name
    #   end
    def output(name)
      @outputs ||= []
      @outputs << name
    end

    # :nodoc:
    def outputs
      @outputs ||= []
    end
  end

  # To implement on children. Defaults to calling all child actors when using
  # `play`.
  # rubocop:disable Metrics/MethodLength
  def call
    self.class.play_actors.each do |actor|
      if actor.is_a?(Class) && actor.ancestors.include?(Actor)
        actor = actor.new_with_context(context)
        actor.call
      else
        actor.call(context)
      end

      (@actors_called ||= []).unshift(actor)
    end
  rescue Actor::Failure
    rollback
    fail!
  end
  # rubocop:enable Metrics/MethodLength

  # To implement on children. Defaults to rolling back child actors when using
  # `play`.
  def rollback
    (@actors_called || []).each do |actor|
      actor.rollback if actor.respond_to?(:rollback)
    end
  end

  # private
  attr_accessor :context

  # :nodoc:
  def apply_defaults
    (self.class.inputs || {}).each do |name, input|
      next if context.respond_to?(name)
      next unless input.key?(:default)

      default = input[:default]
      default = default.call if default.respond_to?(:call)
      context.merge!(name => default)
    end
  end

  private

  # Can be called from inside the actor to stop execution and mark as failed.
  def fail!(**ctx)
    context.fail!(**ctx)
  end
end
