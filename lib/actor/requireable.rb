# frozen_string_literal: true

class Actor
  # Adds `required:` checking to inputs and outputs.
  #
  # Example:
  #
  #   class CreateUser < Actor
  #     input :name, required: true
  #     output :user, required: true
  #   end
  module Requireable
    def before
      super

      check_required_definitions(self.class.inputs, kind: 'Input')
    end

    def after
      super

      check_required_definitions(self.class.outputs, kind: 'Output')
    end

    private

    def check_required_definitions(definitions, kind:)
      definitions.each do |key, options|
        next unless options[:required] && @context[key].nil?

        raise ArgumentError,
              "#{kind} #{key} on #{self.class} is required but was nil."
      end
    end
  end
end
