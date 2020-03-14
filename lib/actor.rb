# frozen_string_literal: true

require 'actor/failure'
require 'actor/success'
require 'actor/context'
require 'actor/filtered_context'

require 'actor/playable'
require 'actor/inputable'
require 'actor/defaultable'
require 'actor/type_checkable'
require 'actor/requireable'
require 'actor/conditionable'

# Actors should start with a verb, inherit from Actor and implement a `call`
# method.
class Actor
  include Inputable
  include Playable
  prepend Defaultable
  prepend TypeCheckable
  prepend Requireable
  prepend Conditionable

  # Call an actor with a given context. Returns the context.
  #
  #   CreateUser.call(name: 'Joe')
  def self.call(context = {}, **arguments)
    context = Actor::Context.to_context(context).merge!(arguments)
    call_with_context(context)
    context
  rescue Actor::Success
    context
  end

  # Call an actor with a given context. Returns the context and does not raise
  # on failure.
  #
  #   CreateUser.result(name: 'Joe')
  def self.result(context = {}, **arguments)
    call(context, **arguments)
  rescue Actor::Failure => e
    e.context
  end

  # :nodoc:
  def self.call_with_context(context)
    actor = new(context)
    actor.before
    actor.call
    actor.after
    actor
  end

  # :nodoc:
  def initialize(context)
    @context = context
  end

  # To implement in your actors.
  def call; end

  # To implement in your actors.
  def rollback; end

  # :nodoc:
  def before; end

  # :nodoc:
  def after; end

  private

  # Returns the current context from inside an actor.
  attr_reader :context

  # Can be called from inside an actor to stop execution and mark as failed.
  def fail!(**arguments)
    @context.fail!(**arguments)
  end

  # Can be called from inside an actor to stop execution early.
  def succeed!(**arguments)
    @context.succeed!(**arguments)
  end
end
