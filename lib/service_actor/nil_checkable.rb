# frozen_string_literal: true

# Ensure your inputs and outputs are not nil by adding `allow_nil: false`.
#
# Example:
#
#   class CreateUser < Actor
#     input :name, allow_nil: false
#     output :user, allow_nil: false
#   end
#
#   class CreateUser < Actor
#     input :name,
#           allow_nil: {
#             is: false,
#             message: (lambda do |origin:, input_key:, actor:|
#               "The value \"#{input_key}\" cannot be empty"
#             end)
#           }
#
#     input :phone, allow_nil: { is: false, message: "Phone must be present" }
#
#     output :user,
#             allow_nil: {
#               is: false,
#               message: (lambda do |origin:, input_key:, actor:|
#                 "The value \"#{input_key}\" cannot be empty"
#               end)
#             }
#   end
module ServiceActor::NilCheckable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    DEFAULT_MESSAGE = lambda do |origin:, input_key:, actor:|
      "The \"#{input_key}\" #{origin} on \"#{actor}\" does not allow " \
      "nil values"
    end

    private_constant :DEFAULT_MESSAGE

    def _call
      check_context_for_nil(self.class.inputs, origin: "input")

      super

      check_context_for_nil(self.class.outputs, origin: "output")
    end

    private

    def check_context_for_nil(definitions, origin:)
      definitions.each do |key, options|
        value = result[key]

        next unless value.nil?

        allow_nil, message = define_allow_nil_from(options[:allow_nil])

        next if allow_nil?(allow_nil, options)

        raise_error_with(
          message,
          origin: origin,
          input_key: key,
          actor: self.class,
        )
      end
    end

    def define_allow_nil_from(allow_nil)
      if allow_nil.is_a?(Hash)
        allow_nil.values_at(:is, :message)
      else
        [allow_nil, DEFAULT_MESSAGE]
      end
    end

    def allow_nil?(allow_nil, options)
      return allow_nil unless allow_nil.nil?
      return true if options.key?(:default) && options[:default].nil?

      !options[:type]
    end
  end
end
