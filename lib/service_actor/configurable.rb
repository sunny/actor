# frozen_string_literal: true

module ServiceActor::Configurable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def inherited(child)
      super

      child.argument_error_class =
        argument_error_class || ServiceActor::ArgumentError

      child.failure_class = failure_class || ServiceActor::Failure
    end

    def argument_error_class=(value)
      ServiceActor::ArgumentsValidator.validate_error_class(value)

      @argument_error_class = value
    end

    def failure_class=(value)
      ServiceActor::ArgumentsValidator.validate_error_class(value)

      @failure_class = value
    end

    attr_reader :argument_error_class, :failure_class
  end
end
