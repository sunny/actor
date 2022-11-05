# frozen_string_literal: true

# Adds `type:` checking to inputs and outputs. Accepts class names or classes
# that should match an ancestor. Also accepts arrays.
#
# Example:
#
#   class ReduceOrderAmount < Actor
#     input :order, type: "Order"
#     input :amount, type: [Integer, Float]
#     input :bonus_applied, type: [TrueClass, FalseClass]
#   end
#
#   class ReduceOrderAmount < Actor
#     input :order, type: { is: Order, message: "Order is required" }
#     input :amount, type: { is: Integer, message: "Incorrect amount" }
#
#     input :bonus_applied,
#           type: {
#             is: [TrueClass, FalseClass],
#             message: (lambda do |origin:, input_key:, actor:, expected_type:, given_type:| # rubocop:disable Layout/LineLength
#               "Wrong type \"#{given_type}\" for \"#{input_key}\". " \
#               "Expected: \"#{expected_type}\""
#             end)
#           }
#   end
class ServiceActor::Checkers::TypeChecker < ServiceActor::Checkers::Base
  DEFAULT_MESSAGE = lambda do
    |origin:, input_key:, actor:, expected_type:, given_type:|

    "The \"#{input_key}\" #{origin} on \"#{actor}\" must be of type " \
      "\"#{expected_type}\" but was \"#{given_type}\""
  end

  private_constant :DEFAULT_MESSAGE

  def self.for( # rubocop:disable Metrics/ParameterLists
    checker_name:,
    origin:,
    input_key:,
    actor:,
    type_definition:,
    given_type:,
    **
  ) # do
    return unless checker_name == :type

    new(
      origin: origin,
      input_key: input_key,
      actor: actor,
      type_definition: type_definition,
      given_type: given_type,
    ).check
  end

  def initialize(origin:, input_key:, actor:, type_definition:, given_type:)
    super()

    @origin = origin
    @input_key = input_key
    @actor = actor
    @type_definition = type_definition
    @given_type = given_type
  end

  def check
    return if @type_definition.nil?
    return if @given_type.nil?

    types, message = define_types_and_message

    return if types.any? { |type| @given_type.is_a?(type) }

    add_argument_error(
      message,
      origin: @origin,
      input_key: @input_key,
      actor: @actor,
      expected_type: types.join(", "),
      given_type: @given_type.class,
    )
  end

  private

  def define_types_and_message
    if @type_definition.is_a?(Hash)
      @type_definition, message =
        @type_definition.values_at(:is, :message)
    else
      message = DEFAULT_MESSAGE
    end

    types = Array(@type_definition).map do |name|
      name.is_a?(String) ? Object.const_get(name) : name
    end

    [types, message]
  end
end
