# frozen_string_literal: true

class ServiceActor::Checks::Base
  def initialize
    @argument_errors = []
  end

  attr_reader :argument_errors

  protected

  def add_argument_error(message, **arguments)
    message = message.call(**arguments) if message.is_a?(Proc)

    argument_errors.push(message)
  end
end
