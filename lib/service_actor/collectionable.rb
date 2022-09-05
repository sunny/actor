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
#             message: (lambda do |_input_key, _in, value|
#               "Payment system \"#{value}\" is not supported"
#             end)
#           }
#   end
module ServiceActor::Collectionable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      self.class.inputs.each do |key, options|
        inclusion = options[:inclusion]

        message = "Input #{key} must be included " \
                  "in #{inclusion.inspect} but instead " \
                  "was #{result[key].inspect}"

        if inclusion.is_a?(Hash) # advanced mode
          inclusion_in, message = inclusion.values_at(:in, :message)
        else
          inclusion_in = inclusion
        end

        next if inclusion_in.nil?
        next if inclusion_in.include?(result[key])

        error_text = if message.is_a?(Proc)
                       message.call(key, inclusion, result[key])
                     else
                       message
                     end

        raise ArgumentError, error_text
      end

      super
    end
  end
end
