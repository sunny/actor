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

          base_arguments = {
            input_key: key,
            check_name: check_name,
            value: value
          }

          check, message = define_check_with(check, **base_arguments)

          next if check.call(value)

          raise_error_with(message, **base_arguments)
        end
      end

      super
    end

    private

    def define_check_with(check, input_key:, check_name:, value:)
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
