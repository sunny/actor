# frozen_string_literal: true

module ServiceActor
  module Core
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Call an actor with a given result. Returns the result.
      #
      #   CreateUser.call(name: 'Joe')
      def call(options = nil, **arguments)
        result = Result.to_result(options).merge!(arguments)
        new(result)._call
        result
      end

      # Call an actor with arguments. Returns the result and does not raise on
      # failure.
      #
      #   CreateUser.result(name: 'Joe')
      def result(data = nil, **arguments)
        call(data, **arguments)
      rescue Failure => e
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

    # Can be called from inside an actor to stop execution and mark as failed.
    def fail!(**arguments)
      result.fail!(**arguments)
    end
  end
end
