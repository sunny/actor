# frozen_string_literal: true

# Adds the `default:` option to inputs. Accepts regular values and lambdas.
# If no default is set and the value has not been given, raises an error.
#
# Example:
#
#   class MultiplyThing < Actor
#     input :counter, default: 1
#     input :multiplier, default: -> { rand(1..10) }
#   end
module ServiceActor::Defaultable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      self.class.inputs.each do |name, input|
        next if result.key?(name)

        if input.key?(:default)
          default = input[:default]
          default = default.call if default.is_a?(Proc)
          result[name] = default
          next
        end

        raise ServiceActor::ArgumentError,
              "Input #{name} on #{self.class} is missing"
      end

      super
    end

    # private

    # def error_text_with(name)
    #   "Input #{name} on #{self.class} is missing"
    # end
  end
end
