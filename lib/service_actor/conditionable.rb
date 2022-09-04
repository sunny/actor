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
#               message: (lambda do |_input_key, _must_key, value|
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
    def _call # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      self.class.inputs.each do |key, options|
        next unless options[:must]

        options[:must].each do |name, content|
          value = result[key]

          if content.is_a?(Hash)
            check, message = content.values_at(:state, :message)
            error_text = message.call(key, name, value)
          else
            check = content
            error_text = "Input #{key} must #{name} but was #{value.inspect}"
          end

          next if check.call(value)

          raise ServiceActor::ArgumentError, error_text
        end
      end

      super
    end
  end
end
