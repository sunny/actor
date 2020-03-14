# frozen_string_literal: true

class Actor
  # Adds the `default:` option to inputs. Accepts regular values and lambdas.
  #
  # Example:
  #
  #   class MultiplyThing < Actor
  #     input :counter, default: 1
  #     input :multiplier, default: -> { rand(1..10) }
  #   end
  module Defaultable
    def before
      (self.class.inputs || {}).each do |name, input|
        next if !input.key?(:default) || context.key?(name)

        default = input[:default]
        default = default.call if default.respond_to?(:call)
        context.merge!(name => default)
      end

      super
    end
  end
end
