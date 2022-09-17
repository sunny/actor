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
module ServiceActor::Collectionable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    DEFAULT_MESSAGE = lambda do |input_key:, actor:, inclusion_in:, value:|
      "The \"#{input_key}\" input must be included " \
      "in #{inclusion_in.inspect} on \"#{actor}\" " \
      "instead of #{value.inspect}"
    end

    private_constant :DEFAULT_MESSAGE

    def _call # rubocop:disable Metrics/MethodLength
      self.class.inputs.each do |key, options|
        value = result[key]

        # DEPRECATED: `in` is deprecated in favor of `inclusion`.
        inclusion = options[:inclusion] || options[:in]

        inclusion_in, message = define_inclusion_from(inclusion)

        next if inclusion_in.nil?
        next if inclusion_in.include?(value)

        raise_error_with(
          message,
          input_key: key,
          actor: self.class,
          inclusion_in: inclusion_in,
          value: value,
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
