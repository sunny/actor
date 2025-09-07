# frozen_string_literal: true

module ActorTypes
  class Boolean
    class << self
      def ===(value)
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end
    end
  end
end

__END__

# Example
class RandomActor < Actor
  input :bool, type: ActorTypes::Boolean
end

RandomActor.call(bool: true) # => #<ServiceActor::Result {bool: true}>
RandomActor.call(bool: "true") # ServiceActor::ArgumentError: The "bool" input on "RandomActor" must be of type "ActorTypes::Boolean" but was "String" (ServiceActor::ArgumentError)
