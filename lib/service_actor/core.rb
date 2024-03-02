# frozen_string_literal: true

module ServiceActor::Core
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Call an actor with a given result. Returns the result.
    #
    #   CreateUser.call(name: "Joe")
    def call(result = nil, **arguments)
      result = ServiceActor::Result.to_result(result).merge!(arguments)

      instance = new(result)
      instance._call

      outputs.each_key do |key|
        result.send("#{key}=", nil) unless result.respond_to?(key)
      end

      result
    end

    # Call an actor with arguments. Returns the result and does not raise on
    # failure.
    #
    #   CreateUser.result(name: "Joe")
    def result(result = nil, **arguments)
      call(result, **arguments)
    rescue failure_class => e
      e.result
    end
  end

  # :nodoc:
  def initialize(result)
    @result = result
  end

  # To implement in your actors.
  def call; end

  # To implement in your actors.
  def rollback; end

  # This method is used internally to override behavior on call. Overriding
  # `call` instead would mean that end-users have to call `super` in their
  # actors.
  # :nodoc:
  def _call
    call
  end

  protected

  # Returns the current context from inside an actor.
  attr_reader :result

  # Can be called from inside an actor to stop execution and mark as failed.
  def fail!(**arguments)
    result.fail!(self.class.failure_class, **arguments)
  end
end
