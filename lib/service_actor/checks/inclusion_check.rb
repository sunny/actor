# frozen_string_literal: true

# Add checks to your inputs, by specifying what values are authorized under the
# "in" key.
#
# Example:
#
#   class Pay < Actor
#     input :provider, inclusion: ["MANGOPAY", "PayPal", "Stripe"]
#   end
#
#   class Pay < Actor
#     input :provider,
#           inclusion: {
#             in: ["MANGOPAY", "PayPal", "Stripe"],
#             message: (lambda do |input_key:, actor:, inclusion_in:, value:|
#               "Payment system \"#{value}\" is not supported"
#             end)
#           }
#   end
class ServiceActor::Checks::InclusionCheck < ServiceActor::Checks::Base
  DEFAULT_MESSAGE = lambda do |input_key:, actor:, inclusion_in:, value:|
    "The \"#{input_key}\" input must be included " \
      "in #{inclusion_in.inspect} on \"#{actor}\" " \
      "instead of #{value.inspect}"
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
      # DEPRECATED: `in` is deprecated in favor of `inclusion`.
      return unless %i[inclusion in].include?(check_name)

      new(
        input_key: input_key,
        actor: actor,
        inclusion: conditions,
        value: result[input_key],
        input_options: input_options,
      ).check
    end
  end

  def initialize(input_key:, actor:, inclusion:, value:, input_options:)
    super()

    @input_key = input_key
    @actor = actor
    @inclusion = inclusion
    @value = value
    @input_options = input_options
  end

  def check
    inclusion_in, message = define_inclusion_and_message

    return if inclusion_in.nil?
    return if inclusion_in.include?(value)
    return if input_options[:allow_nil] && value.nil?

    add_argument_error(
      message,
      input_key: input_key,
      actor: actor,
      inclusion_in: inclusion_in,
      value: value,
    )
  end

  private

  attr_reader :value, :inclusion, :input_key, :actor, :input_options

  def define_inclusion_and_message
    if inclusion.is_a?(Hash)
      inclusion[:message] ||= DEFAULT_MESSAGE
      inclusion.values_at(:in, :message)
    else
      [inclusion, DEFAULT_MESSAGE]
    end
  end
end
