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
#             message: (lambda do |_origin, _input_key, _service_name|
#               "The value `#{input_key}` cannot be empty"
#             end)
#           }
#
#     output :user,
#             allow_nil: {
#               is: false,
#               message: (lambda do |_origin, _input_key, _service_name|
#                 "The value `#{input_key}` cannot be empty"
#               end)
#             }
#   end
module ServiceActor::NilCheckable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      check_context_for_nil(self.class.inputs, origin: "input")

      super

      check_context_for_nil(self.class.outputs, origin: "output")
    end

    private

    def check_context_for_nil(definitions, origin:) # rubocop:disable Metrics/MethodLength
      definitions.each do |key, options|
        value = result[key]

        next unless value.nil?

        base_arguments = {
          origin: origin,
          input_key: key,
          service_name: self.class
        }

        allow_nil, message = define_allow_nil_with(
          options[:allow_nil],
          **base_arguments,
        )

        next if allow_nil?(allow_nil, options)

        raise_error_with(message, **base_arguments)
      end
    end

    def define_allow_nil_with(allow_nil, origin:, input_key:, service_name:)
      if allow_nil.is_a?(Hash) # advanced mode
        allow_nil, message = allow_nil.values_at(:is, :message)
      else
        message =
          "The #{origin} \"#{input_key}\" on #{service_name} does not allow " \
          "nil values"
      end

      [
        allow_nil,
        message
      ]
    end

    def allow_nil?(allow_nil, options)
      return allow_nil unless allow_nil.nil?
      return true if options.key?(:default) && options[:default].nil?

      !options[:type]
    end
  end
end
