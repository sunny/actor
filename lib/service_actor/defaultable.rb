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
#
#   class MultiplyThing < Actor
#     input :counter,
#           default: {
#             is: 1,
#             message: "Counter is required"
#           }
#
#     input :multiplier,
#           default: {
#             is: -> { rand(1..10) },
#             message: (lambda do |input_key:, actor:|
#               "Input \"#{input_key}\" is required"
#             end)
#           }
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

      if default.is_a?(Hash) && default[:is]
        default_for_advanced_mode_with(result, origin_name, default)
      else
        default_for_normal_mode_with(result, origin_name, default)
      end
    end

    def default_for_normal_mode_with(result, key, default)
      result[key] = reify_default(result, default)
    end

    def default_for_advanced_mode_with(result, key, content)
      default, message = content.values_at(:is, :message)

      unless default
        raise_error_with(message, input_key: key, actor: self.class)
      end

      result[key] = reify_default(result, default)

      message.call(key, self.class)
    end

    # Raises an error depending on the mode
    def raise_error_with(message, **arguments)
      message = message.call(**arguments) if message.is_a?(Proc)

      raise self.class.argument_error_class, message
    end

    def reify_default(result, default)
      return default unless default.is_a?(Proc)

      default.arity.zero? ? default.call : default.call(result)
    end
  end
end
