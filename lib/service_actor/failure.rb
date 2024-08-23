# frozen_string_literal: true

# Default error raised when using `fail!` inside an actor.
class ServiceActor::Failure < ServiceActor::Error
  def initialize(result)
    @result = result

    error = result.respond_to?(:error) ? result.error : nil

    super(error)
  end

  attr_reader :result
end
