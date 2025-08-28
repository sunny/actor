# frozen_string_literal: true

# Add checks to your inputs, by calling lambdas with the name of you choice
# under the "must" key.
#
# Will raise an error if any check returns a truthy value.
#
# Example:
#
#   class Pay < Actor
#     input :provider,
#           must: {
#             exist: -> provider { PROVIDERS.include?(provider) },
#           }
#   end
#
#   class Pay < Actor
#     input :provider,
#           must: {
#             exist: {
#               is: -> provider { PROVIDERS.include?(provider) },
#               message: (lambda do |input_key:, check_name:, actor:, value:|
#                 "The specified provider \"#{value}\" was not found."
#               end)
#             }
#           }
#   end
class ServiceActor::Checks::MustCheck < ServiceActor::Checks::Base
  DEFAULT_MESSAGE = lambda do |input_key:, actor:, check_name:, value:|
    "The \"#{input_key}\" input on \"#{actor}\" must \"#{check_name}\" " \
      "but was #{value.inspect}"
  end

  private_constant :DEFAULT_MESSAGE

  class << self
    def check(
      check_name:,
      input_key:,
      actor:,
      conditions:,
      result:,
      input_options:,
      **
    )
      return unless check_name == :must

      new(
        input_key: input_key,
        actor: actor,
        nested_checks: conditions,
        value: result[input_key],
        input_options: input_options,
      ).check
    end
  end

  def initialize(input_key:, actor:, nested_checks:, value:, input_options:)
    super()

    @input_key = input_key
    @actor = actor
    @nested_checks = nested_checks
    @value = value
    @input_options = input_options
  end

  def check
    return if input_options[:allow_nil] && value.nil?

    nested_checks.each do |nested_check_name, nested_check_conditions|
      message = prepared_message_with(
        nested_check_name,
        nested_check_conditions,
      )

      next unless message

      add_argument_error(
        message,
        input_key: input_key,
        actor: actor,
        check_name: nested_check_name,
        value: value,
      )
    end

    argument_errors
  end

  private

  attr_reader :input_key, :actor, :nested_checks, :value, :input_options

  def prepared_message_with(nested_check_name, nested_check_conditions)
    check, message = define_check_and_message_from(nested_check_conditions)

    return if check.call(value)

    message
  rescue StandardError => e
    "The \"#{input_key}\" input on \"#{actor}\" has an error in the code " \
      "inside \"#{nested_check_name}\": [#{e.class}] #{e.message}"
  end

  def define_check_and_message_from(nested_check_conditions)
    if nested_check_conditions.is_a?(Hash)
      nested_check_conditions[:message] ||= DEFAULT_MESSAGE
      nested_check_conditions.values_at(:is, :message)
    else
      [nested_check_conditions, DEFAULT_MESSAGE]
    end
  end
end
