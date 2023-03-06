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
class ServiceActor::Checks::DefaultCheck < ServiceActor::Checks::Base
  def self.check(origin:, input_key:, actor:, result:, input_options:, **) # rubocop:disable Metrics/ParameterLists
    new(
      origin: origin,
      input_key: input_key,
      actor: actor,
      result: result,
      input_options: input_options,
    ).check
  end

  def initialize(origin:, input_key:, actor:, result:, input_options:)
    super()

    @origin = origin
    @input_key = input_key
    @actor = actor
    @result = result
    @input_options = input_options
  end

  def check # rubocop:disable Metrics/MethodLength
    return if @result.key?(@input_key)

    unless @input_options.key?(:default)
      return add_argument_error(
        "The \"#{@input_key}\" #{@origin} on \"#{@actor}\" is missing",
      )
    end

    default = @input_options[:default]

    if default.is_a?(Hash)
      default_for_advanced_mode_with(default)
    else
      default_for_normal_mode_with(default)
    end

    nil
  end

  private

  def default_for_normal_mode_with(default)
    default = default.call if default.is_a?(Proc)
    @result[@input_key] = default
  end

  def default_for_advanced_mode_with(content)
    default, message = content.values_at(:is, :message)

    unless default
      return add_argument_error(
        message,
        input_key: @input_key,
        actor: self.class,
      )
    end

    default = default.call if default.is_a?(Proc)
    @result[@input_key] = default

    message.call(@input_key, self.class)
  end
end
