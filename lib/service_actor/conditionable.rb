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
#
#   class Pay < Actor
#     input :provider,
#           must: {
#             exist: {
#               state: -> provider { PROVIDERS.include?(provider) },
#               message: (lambda do |_input_key, _check_name, value|
#                 "The specified provider \"#{value}\" was not found."
#               end)
#             }
#           }
#   end
module ServiceActor::Conditionable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call # rubocop:disable Metrics/MethodLength
      self.class.inputs.each do |key, options|
        next unless options[:must]

        options[:must].each do |check_name, check|
          value = result[key]

          # FIXME: The `prototype_2_with` method needs to be renamed.
          check, message = prototype_2_with(
            check,
            input_key: key,
            check_name: check_name,
            value: value,
          )

          next if check.call(value)

          raise_error_with(
            message,
            input_key: key,
            check_name: check_name,
            value: value,
          )
        end
      end

      super
    end

    private

    def prototype_2_with(check, input_key:, check_name:, value:)
      if check.is_a?(Hash) # advanced mode
        check, message = check.values_at(:state, :message)
      else
        message =
          "Input #{input_key} must #{check_name} but was #{value.inspect}"
      end

      [
        check,
        message
      ]
    end
  end
end
