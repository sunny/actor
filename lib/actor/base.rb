# frozen_string_literal: true

require 'actor/attributable'
require 'actor/playable'

class Actor
  # Actors should start with a verb, inherit from Actor and implement a `call`
  # method.
  module Base
    def self.included(base)
      base.extend(Actor::ClassMethods)
      base.include(Actor::Attributable)
      base.include(Actor::Playable)
    end

    module ClassMethods
      # Call an actor with a given result. Returns the result.
      #
      #   CreateUser.call(name: 'Joe')
      def call(options = nil, **arguments)
        result = Actor::Result.to_result(options).merge!(arguments)
        new(result)._call
        result
      rescue Actor::Success
        result
      end

      # :nodoc:
      def call!(**arguments)
        warn "DEPRECATED: Prefer `#{name}.call` to `#{name}.call!`."
        call(**arguments)
      end

      # Call an actor with arguments. Returns the result and does not raise on
      # failure.
      #
      #   CreateUser.result(name: 'Joe')
      def result(data = nil, **arguments)
        call(data, **arguments)
      rescue Actor::Failure => e
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

    # :nodoc:
    def _call
      call
    end

    private

    # Returns the current context from inside an actor.
    attr_reader :result

    def context
      warn "DEPRECATED: Prefer `result.` to `context.` in #{self.class.name}."

      result
    end

    # Can be called from inside an actor to stop execution and mark as failed.
    def fail!(**arguments)
      result.fail!(**arguments)
    end

    # Can be called from inside an actor to stop execution early.
    def succeed!(**arguments)
      result.succeed!(**arguments)
    end
  end
end
