# frozen_string_literal: true

# Add checks to your inputs, by specifying what values are authorized under the
# "in" key.
#
# Example:
#
#   class Pay < Actor
#     input :provider, in: ["MANGOPAY", "PayPal", "Stripe"]
#   end
module ServiceActor::Collectionable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      self.class.inputs.each do |key, options|
        next unless options[:in]

        next if options[:in].include?(result[key])

        raise ArgumentError, error_text_with(key, options, result)
      end

      super
    end

    private

    def error_text_with(key, options, result)
      "Input #{key} must be included in #{options[:in].inspect} " \
      "but instead was #{result[key].inspect}"
    end
  end
end
