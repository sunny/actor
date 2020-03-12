# frozen_string_literal: true

require 'actor/failure'
require 'actor/context'
require 'actor/filtered_context'

# Actors should start with a verb, inherit from Actor and implement a `call`
# method.
class Actor
  class << self
    # Call an actor with a given context. Returns the context.
    #
    #   CreateUser.call(name: 'Joe')
    def call(context = {}, **arguments)
      context = Actor::Context.to_context(context)
      new_and_call(context.merge!(arguments))
      context
    end

    # Call an actor with a given context. Returns the context and does not raise
    # on failure.
    #
    #   CreateUser.call(name: 'Joe')
    def result(context = {}, **arguments)
      call(context, **arguments)
    rescue Actor::Failure => e
      e.context
    end

    # :nodoc:
    def new_and_call(context)
      actor = new(context)
      actor.apply_defaults
      actor.call
      actor
    end

    # DSL to call a series of actors with the same context. On failure, calls
    # rollback on any actor that succeeded.
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
      inputs[name] = arguments

      define_method(name) do
        context.public_send(name)
      end

      private name
    end

    # :nodoc:
    def inputs
      @inputs ||= {}
    end

    # DSL to document the exposed attributes.
    #
    #   class CreateUser < Actor
    #     output :name
    #   end
    def output(name)
      outputs << name
    end

    def outputs
      @outputs ||= [:error]
    end
  end

  # :nodoc:
  def initialize(context)
    @full_context = context
  end

  # To implement on your actors. When using `play`, this defaults to calling
  # all listed actors.
  def call
    self.class.play_actors.each do |actor|
      if actor.respond_to?(:new_and_call)
        actor = actor.new_and_call(@full_context)
      else
        actor.call(@full_context)
      end

      (@played_actors ||= []).unshift(actor)
    end
  rescue Actor::Failure
    rollback
    raise
  end

  # To implement on your actors. When using `play`, this defaults to rolling
  # back all the previous actors that have been called.
  def rollback
    (@played_actors || []).each do |actor|
      next unless actor.respond_to?(:rollback)

      actor.rollback
    end
  end

  # :nodoc:
  def apply_defaults
    (self.class.inputs || {}).each do |name, input|
      next if !input.key?(:default) || @full_context.key?(name)

      default = input[:default]
      default = default.call if default.respond_to?(:call)
      @full_context.merge!(name => default)
    end
  end

  # :nodoc:
  attr_writer :context

  private

  def context
    @context ||= Actor::FilteredContext.new(
      @full_context,
      readers: self.class.inputs.keys,
      setters: self.class.outputs,
    )
  end

  # Can be called from inside the actor to stop execution and mark as failed.
  def fail!(**ctx)
    @full_context.fail!(**ctx)
  end
end
