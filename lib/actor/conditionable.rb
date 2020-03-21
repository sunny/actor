# frozen_string_literal: true

class Actor
  # Add checks to your inputs, by calling lambdas with the name of you choice.
  # Will raise an error if any check does return a truthy value.
  #
  # Example:
  #
  #   class Pay < Actor
  #     input :provider,
  #           must: {
  #             exist: ->(provider) { PROVIDERS.include?(provider) }
  #           }
  #   end
  module Conditionable
    def before
      super

      self.class.inputs.each do |key, options|
        next unless options[:must]

        options[:must].each do |name, check|
          value = context[key]
          next if check.call(value)

          raise Actor::ArgumentError,
                "Input #{key} must #{name} but was #{value.inspect}."
        end
      end
    end
  end
end
