# frozen_string_literal: true

module ServiceActor
  # Adds the `default:` option to inputs. Accepts regular values and lambdas.
  # If no default is set and the value has not been given, raises an error.
  #
  # Example:
  #
  #   class MultiplyThing < Actor
  #     input :counter, default: 1
  #     input :multiplier, default: -> { rand(1..10) }
  #   end
  module Defaultable
    def self.included(base)
      base.prepend(PrependedMethods)
    end

    module PrependedMethods
      def _call
        self.class.inputs.each do |name, input|
          next if result.key?(name)

          unless input.key?(:default)
            raise ArgumentError, "Input #{name} on #{self.class} is missing."
          end

          default = input[:default]
          default = default.call if default.respond_to?(:call)
          result[name] = default
        end

        super
      end
    end
  end
end
