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
#               is: -> provider { PROVIDERS.include?(provider) },
#               message: (lambda do |input_key:, check_name:, actor:, value:|
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
    DEFAULT_MESSAGE = lambda do |input_key:, check_name:, actor:, value:|
      "The \"#{input_key}\" input on \"#{actor}\" must \"#{check_name}\" " \
        "but was #{value.inspect}"
    end

    private_constant :DEFAULT_MESSAGE

    def _call # rubocop:disable Metrics/MethodLength
      self.class.inputs.each do |key, options|
        next unless options[:must]

        options[:must].each do |check_name, check|
          value = result[key]

          check, message = define_check_from(check)

          next if check.call(value)

          raise_error_with(
            message,
            input_key: key,
            check_name: check_name,
            actor: self.class,
            value: value,
          )
        end
      end

      super
    end

    private

    def define_check_from(check)
      if check.is_a?(Hash)
        check.values_at(:is, :message)
      else
        [check, DEFAULT_MESSAGE]
      end
    end
  end
end
