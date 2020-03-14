# frozen_string_literal: true

class Actor
  # Error raised when using `fail!` inside an actor.
  class Failure < StandardError
    def initialize(context)
      @context = context

      error = context.respond_to?(:error) ? context.error : nil

      super(error)
    end

    attr_reader :context
  end
end
