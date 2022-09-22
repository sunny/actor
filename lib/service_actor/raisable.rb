# frozen_string_literal: true

module ServiceActor::Raisable
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

    attr_accessor :argument_error_class, :failure_class
  end
end
