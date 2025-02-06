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
  class << self
    def included(base)
      base.prepend(PrependedMethods)
    end
  end

  module PrependedMethods
    def _call # rubocop:disable Metrics/MethodLength
      self.class.inputs.each do |key, input|
        next if result.key?(key)

        unless input.key?(:default)
          raise_error_with(
            "The \"#{key}\" input on \"#{self.class}\" is missing",
          )
        end

        apply_default_for_origin(key, input)
      end

      self.class.outputs.each do |key, output|
        next if result.key?(key)

        apply_default_for_origin(key, output)
      end

      super
    end

    private

    def apply_default_for_origin(origin_name, origin_options)
      default = origin_options[:default]

      result[origin_name] = reify_default(result, default)
    end

    def raise_error_with(message)
      raise self.class.argument_error_class, message
    end

    def reify_default(result, default)
      return default unless default.is_a?(Proc)

      default.arity.zero? ? default.call : default.call(result)
    end
  end
end
