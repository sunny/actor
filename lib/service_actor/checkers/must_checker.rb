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
class ServiceActor::Checkers::MustChecker < ServiceActor::Checkers::Base
  DEFAULT_MESSAGE = lambda do |input_key:, actor:, check_name:, value:|
    "The \"#{input_key}\" input on \"#{actor}\" must \"#{check_name}\" " \
      "but was #{value.inspect}"
  end

  private_constant :DEFAULT_MESSAGE

  def self.for(checker_name:, input_key:, actor:, nested_checkers:, value:)
    return unless checker_name == :must

    new(
      input_key: input_key,
      actor: actor,
      nested_checkers: nested_checkers,
      value: value,
    ).check
  end

  def initialize(input_key:, actor:, nested_checkers:, value:)
    super()

    @input_key = input_key
    @actor = actor
    @nested_checkers = nested_checkers
    @value = value
  end

  def check
    @nested_checkers.each do |nested_checker_name, nested_checker_conditions|
      check, message = define_check_and_message_from(nested_checker_conditions)

      next if check.call(@value)

      add_argument_error(
        message,
        input_key: @input_key,
        actor: @actor,
        check_name: nested_checker_name,
        value: @value,
      )
    end

    @argument_errors
  end

  private

  def define_check_and_message_from(nested_checker_conditions)
    if nested_checker_conditions.is_a?(Hash)
      nested_checker_conditions.values_at(:is, :message)
    else
      [nested_checker_conditions, DEFAULT_MESSAGE]
    end
  end
end
