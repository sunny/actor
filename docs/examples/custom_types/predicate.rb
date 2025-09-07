# frozen_string_literal: true

module ActorTypes
  class Predicate
    def initialize(predicate_name)
      @predicate_name = predicate_name
    end

    def name
      "Predicate ##{@predicate_name}"
    end

    def ===(value)
      value.respond_to?(@predicate_name) && value.public_send(@predicate_name)
    end

    class << self
      def [](predicate_name)
        new(predicate_name)
      end
    end
  end
end

__END__

# Example
class DivisionActor < Actor
  input :dividend, type: Numeric
  input :divisor, type: ActorTypes::Predicate[:nonzero?]

  output :outcome, type: Numeric

  def call
    self.outcome = dividend / divisor
  end
end

DivisionActor.call(dividend: 42, divisor: 6).outcome # => 7
DivisionActor.call(dividend: 42, divisor: 0).outcome # ServiceActor::ArgumentError: The "divisor" input on "DivisionActor" must be of type "Predicate #nonzero?" but was "Integer" (ServiceActor::ArgumentError)
