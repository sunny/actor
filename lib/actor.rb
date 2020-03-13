# frozen_string_literal: true

require 'actor/failure'
require 'actor/context'
require 'actor/filtered_context'

require 'actor/type_checkable'
require 'actor/defaultable'

# Actors should start with a verb, inherit from Actor and implement a `call`
# method.
class Actor
  prepend Defaultable
  prepend TypeCheckable

  class << self
    # Call an actor with a given context. Returns the context.
    #
    #   CreateUser.call(name: 'Joe')
    def call(context = {}, **arguments)
      context = Actor::Context.to_context(context)
      actor = new(context.merge!(arguments))
      actor.trigger
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
    def output(name, **arguments)
      outputs[name] = arguments
    end

    def outputs
      @outputs ||= { error: { type: 'String' } }
    end
  end

  # :nodoc:
  def initialize(full_context)
    @full_context = full_context
  end

  # To implement on your actors. When using `play`, this defaults to calling
  # all listed actors.
  def call
    self.class.play_actors.each do |actor|
      if actor.is_a?(Class)
        actor = actor.new(@full_context)
        actor.trigger
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
  def trigger
    before
    call
    after
  end

  # :nodoc:
  attr_writer :context

  private

  def context
    @context ||= Actor::FilteredContext.new(
      @full_context,
      readers: self.class.inputs.keys,
      setters: self.class.outputs.keys,
    )
  end

  def before; end

  def after; end

  # Can be called from inside the actor to stop execution and mark as failed.
  def fail!(**ctx)
    @full_context.fail!(**ctx)
  end
end
