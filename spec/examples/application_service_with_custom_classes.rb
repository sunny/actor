# frozen_string_literal: true

class ApplicationServiceWithCustomClasses
  include ServiceActor::Base

  self.argument_error_class = MyCustomArgumentError
  self.failure_class = MyCustomFailure
end
