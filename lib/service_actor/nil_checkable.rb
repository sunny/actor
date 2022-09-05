# frozen_string_literal: true

# Ensure your inputs and outputs are not nil by adding `allow_nil: false`.
#
# Example:
#
#   class CreateUser < Actor
#     input :name, allow_nil: false
#     output :user, allow_nil: false
#   end
#
#   class CreateUser < Actor
#     input :name,
#           allow_nil: false,
#           allow_nil_message: (lambda do |_origin, _input_key, _service_name|
#             "The value `#{input_key}` cannot be empty"
#           end)
#
#     output :user,
#            allow_nil: false,
#            allow_nil_message: (lambda do |_origin, _input_key, _service_name|
#              "The value `#{input_key}` cannot be empty"
#            end)
#   end
module ServiceActor::NilCheckable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      check_context_for_nil(self.class.inputs, origin: "input")

      super

      check_context_for_nil(self.class.outputs, origin: "output")
    end

    private

    def check_context_for_nil(definitions, origin:)
      definitions.each do |key, options|
        next if !result[key].nil? || allow_nil?(options)

        message = "The #{origin} \"#{key}\" on #{self.class} does not allow " \
                  "nil values"

        message = options[:allow_nil_message] if allow_nil_message?(options)

        error_text = if message.is_a?(Proc)
                       message.call(origin, key, self.class)
                     else
                       message
                     end

        raise ServiceActor::ArgumentError, error_text
      end
    end

    def allow_nil?(options)
      return options[:allow_nil] if options.key?(:allow_nil)
      return true if options.key?(:default) && options[:default].nil?

      !options[:type]
    end

    def allow_nil_message?(options)
      return !!options[:allow_nil_message] if options.key?(:allow_nil_message)

      false
    end
  end
end
