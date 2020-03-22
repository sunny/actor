# frozen_string_literal: true

module ServiceActor
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

            raise ArgumentError,
                  "Input #{key} must #{name} but was #{value.inspect}."
          end
        end

        super
      end
    end
  end
end
