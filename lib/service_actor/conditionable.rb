# frozen_string_literal: true

# Add checks to your inputs, by calling lambdas with the name of you choice
# under the "must" key.
#
# Will raise an error if any check returns a truthy value.
#
# Example:
#
#   class Pay < Actor
#     input :provider,
#           must: {
#             exist: -> provider { PROVIDERS.include?(provider) },
#           }
#   end
module ServiceActor::Conditionable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      self.class.inputs.each do |key, options|
        next unless options[:must]

        options[:must].each do |name, check|
          value = result[key]
          next if check.call(value)

          raise self.class.argument_error_class,
                "Input #{key} must #{name} but was #{value.inspect}"
        end
      end

      super
    end
  end
end
