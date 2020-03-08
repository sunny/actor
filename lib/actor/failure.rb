# frozen_string_literal: true

class Actor
  # Error raised when using `fail!` inside an actor.
  class Failure < StandardError
    def initialize(context)
      @context = context

      super(context.respond_to?(:error) ? context.error : nil)
    end

    attr_reader :context
  end
end
