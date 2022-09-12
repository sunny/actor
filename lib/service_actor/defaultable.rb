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
  def self.included(base)
    base.prepend(PrependedMethods)
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

        default = input[:default]

        if default.is_a?(Hash)
          default_for_advanced_mode_with(result, key, default)
        else
          default_for_normal_mode_with(result, key, default)
        end
      end

      super
    end

    private

    def default_for_normal_mode_with(result, key, default)
      default = default.call if default.is_a?(Proc)
      result[key] = default
    end

    def default_for_advanced_mode_with(result, key, content)
      default, message = content.values_at(:is, :message)

      unless default
        raise_error_with(message, input_key: key, actor: self.class)
      end

      default = default.call if default.is_a?(Proc)
      result[key] = default

      message.call(key, self.class)
    end
  end
end
