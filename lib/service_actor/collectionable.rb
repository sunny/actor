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
    DEFAULT_MESSAGE = lambda do |input_key, value, inclusion_in|
      "Input #{input_key} must be included " \
      "in #{inclusion_in.inspect} but instead " \
      "was #{value.inspect}"
    end

    private_constant :DEFAULT_MESSAGE

    def _call # rubocop:disable Metrics/MethodLength
      self.class.inputs.each do |key, options|
        value = result[key]

        # DEPRECATED: `in` is deprecated in favor of `inclusion`.
        inclusion = options[:inclusion] || options[:in]

        base_arguments = {
          input_key: key,
          value: value
        }

        inclusion_in, message = define_inclusion_from(inclusion)

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

    def define_inclusion_from(inclusion)
      if inclusion.is_a?(Hash)
        inclusion.values_at(:in, :message)
      else
        [inclusion, DEFAULT_MESSAGE]
      end
    end
  end
end
