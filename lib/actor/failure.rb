# frozen_string_literal: true

class Actor
  # Error raised when using `fail!` inside an actor.
  class Failure < Actor::Error
    def initialize(result)
      @result = result

      error = result.respond_to?(:error) ? result.error : nil

      super(error)
    end

    attr_reader :result
  end
end
