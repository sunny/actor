# frozen_string_literal: true

# Add checks to your inputs, by specifying what values are authorized under the
# "in" key.
#
# Example:
#
#   class Pay < Actor
#     input :provider, inclusion: ["MANGOPAY", "PayPal", "Stripe"]
#   end
module ServiceActor::Collectionable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      self.class.inputs.each do |key, options|
        # DEPRECATED: `in` is deprecated in favor of `inclusion`.
        inclusion = options[:inclusion] || options[:in]
        next unless inclusion

        next if inclusion.include?(result[key])

        raise ServiceActor::ArgumentError,
              "Input #{key} must be included in #{inclusion.inspect} " \
              "but instead was #{result[key].inspect}"
      end

      super
    end
  end
end
