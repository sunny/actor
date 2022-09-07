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
#             message: (lambda do |_input_key, value, _inclusion_in|
#               "Payment system \"#{value}\" is not supported"
#             end)
#           }
#   end
module ServiceActor::Collectionable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call # rubocop:disable Metrics/MethodLength
      self.class.inputs.each do |key, options|
        value = result[key]
        inclusion = options[:inclusion]

        base_arguments = {
          input_key: key,
          value: value
        }

        inclusion_in, message =
          define_inclusion_with(inclusion, **base_arguments)

        next if inclusion_in.nil?
        next if inclusion_in.include?(value)

        raise_error_with(
          message,
          **base_arguments,
          inclusion_in: inclusion_in,
        )
      end

      super
    end

    private

    def define_inclusion_with(inclusion, input_key:, value:)
      if inclusion.is_a?(Hash) # advanced mode
        inclusion_in, message = inclusion.values_at(:in, :message)
      else
        inclusion_in = inclusion
        message = "Input #{input_key} must be included " \
                  "in #{inclusion_in.inspect} but instead " \
                  "was #{value.inspect}"
      end

      [
        inclusion_in,
        message
      ]
    end
  end
end
